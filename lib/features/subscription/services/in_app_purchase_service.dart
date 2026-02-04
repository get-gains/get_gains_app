// lib/features/subscription/services/in_app_purchase_service.dart

import 'dart:async';
import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/logger.dart';
import '../data/models/models.dart';

part 'in_app_purchase_service.g.dart';

/// Purchase status for UI feedback
enum PurchaseState {
  /// No purchase in progress
  idle,

  /// Purchase is being processed
  purchasing,

  /// Purchase completed successfully
  completed,

  /// Purchase was canceled by user
  canceled,

  /// Purchase failed with error
  error,

  /// Purchase is pending (e.g., awaiting payment)
  pending,
}

/// Result of a purchase operation
class PurchaseResult {
  const PurchaseResult({
    required this.status,
    this.purchaseDetails,
    this.errorMessage,
  });

  final PurchaseState status;
  final PurchaseDetails? purchaseDetails;
  final String? errorMessage;

  bool get isSuccess => status == PurchaseState.completed;
  bool get isPending => status == PurchaseState.pending;
  bool get isCanceled => status == PurchaseState.canceled;
  bool get isError => status == PurchaseState.error;
}

/// In-App Purchase Service
///
/// Handles platform-specific in-app purchases via the in_app_purchase package.
/// Provides a unified interface for:
/// - Checking store availability
/// - Loading products from the store
/// - Initiating purchases
/// - Processing purchase updates
///
/// Usage:
/// ```dart
/// final iapService = ref.read(inAppPurchaseServiceProvider);
///
/// // Initialize and load products
/// await iapService.initialize(['premium_monthly', 'premium_yearly']);
///
/// // Check if product is available
/// final product = iapService.getProduct('premium_monthly');
///
/// // Purchase a product
/// final result = await iapService.purchaseProduct('premium_monthly');
/// if (result.isSuccess) {
///   // Verify with backend
///   await subscriptionRepo.verifyPurchase(...);
/// }
/// ```
class InAppPurchaseService {
  InAppPurchaseService() {
    _purchaseStream = _inAppPurchase.purchaseStream;
  }

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late final Stream<List<PurchaseDetails>> _purchaseStream;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final _purchaseController = StreamController<PurchaseResult>.broadcast();

  /// Stream of purchase results
  Stream<PurchaseResult> get purchaseResults => _purchaseController.stream;

  /// Loaded products from the store
  final Map<String, ProductDetails> _products = {};

  /// Maps full productId (with base plan) to store productId
  /// e.g., "get_gains.premium:premium-subscription" -> "get_gains.premium"
  final Map<String, String> _productIdMapping = {};

  /// Whether the store is available
  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  /// Whether the service has been initialized
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize the service and load products
  ///
  /// [productIds] - List of product IDs to load from the store
  /// Returns true if initialization was successful
  Future<bool> initialize(List<String> productIds) async {
    if (_isInitialized) {
      AppLogger.warning('InAppPurchaseService already initialized', tag: 'IAP');
      return _isAvailable;
    }

    AppLogger.debug('Initializing InAppPurchaseService', tag: 'IAP');

    // Check store availability
    _isAvailable = await _inAppPurchase.isAvailable();
    if (!_isAvailable) {
      AppLogger.warning(
        'Store is not available. This can happen if:\n'
        '  1. Google Play Store is not installed\n'
        '  2. Device is an emulator without Play Store\n'
        '  3. Play Store needs to be updated\n'
        '  4. Network connectivity issues',
        tag: 'IAP',
      );
      _isInitialized = true;
      return false;
    }
    AppLogger.info('Store is available', tag: 'IAP');

    // Start listening to purchase updates
    _subscription = _purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (error) {
        AppLogger.error('Purchase stream error', tag: 'IAP', error: error);
        _purchaseController.add(
          PurchaseResult(
            status: PurchaseState.error,
            errorMessage: 'Purchase stream error: $error',
          ),
        );
      },
    );

    // Load products
    if (productIds.isNotEmpty) {
      await loadProducts(productIds);
    }

    _isInitialized = true;
    AppLogger.info('InAppPurchaseService initialized', tag: 'IAP');
    return true;
  }

  /// Load products from the store
  ///
  /// [productIds] - Product IDs to query (may include base plan IDs like "product:basePlan")
  Future<void> loadProducts(List<String> productIds) async {
    if (!_isAvailable) {
      AppLogger.warning(
        'Cannot load products - store not available',
        tag: 'IAP',
      );
      return;
    }

    // Extract store product IDs (before the colon) and build mapping
    // e.g., "get_gains.premium:premium-subscription" -> "get_gains.premium"
    _productIdMapping.clear();
    final storeProductIds = <String>{};
    for (final fullId in productIds) {
      final storeId = _extractStoreProductId(fullId);
      storeProductIds.add(storeId);
      _productIdMapping[fullId] = storeId;
    }

    AppLogger.debug(
      'Loading products: $storeProductIds (mapped from $productIds)',
      tag: 'IAP',
    );

    try {
      // Add timeout to prevent hanging indefinitely
      // Note: Timeout usually means Google Play can't find products, not a network issue
      final response = await _inAppPurchase
          .queryProductDetails(storeProductIds)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              AppLogger.error(
                'Product query timed out after 15 seconds.\n'
                'Common causes:\n'
                '  1. App not uploaded to Google Play Console (internal test track)\n'
                '  2. Product "$storeProductIds" not created in Play Console\n'
                '  3. App signed with different key than Play Console upload\n'
                '  4. License tester not configured in Play Console\n'
                '  5. Running debug build instead of release build',
                tag: 'IAP',
              );
              throw TimeoutException('Product query timed out');
            },
          );

      AppLogger.debug(
        'Query response - found: ${response.productDetails.length}, notFound: ${response.notFoundIDs}, error: ${response.error}',
        tag: 'IAP',
      );

      if (response.notFoundIDs.isNotEmpty) {
        AppLogger.warning(
          'Products not found in store: ${response.notFoundIDs}',
          tag: 'IAP',
        );
      }

      if (response.error != null) {
        AppLogger.error(
          'Error loading products: ${response.error?.message}',
          tag: 'IAP',
        );
        return;
      }

      _products.clear();
      for (final product in response.productDetails) {
        // For subscriptions, store by composite key (subscriptionId:basePlanId)
        // This allows matching with server's productId format
        if (product is GooglePlayProductDetails &&
            product.subscriptionIndex != null) {
          final subscriptionOfferDetails =
              product.productDetails.subscriptionOfferDetails;
          if (subscriptionOfferDetails != null &&
              product.subscriptionIndex! < subscriptionOfferDetails.length) {
            final basePlanId =
                subscriptionOfferDetails[product.subscriptionIndex!].basePlanId;
            final compositeKey = '${product.id}:$basePlanId';
            _products[compositeKey] = product;
            // Also store by simple ID for fallback (last one wins)
            _products[product.id] = product;
            AppLogger.debug(
              'Loaded subscription: $compositeKey (basePlan: $basePlanId, offerToken: ${product.offerToken})',
              tag: 'IAP',
            );
            continue;
          }
        }
        // Non-subscription products or fallback
        _products[product.id] = product;
        AppLogger.debug(
          'Loaded product: ${product.id} - ${product.title}',
          tag: 'IAP',
        );
      }

      AppLogger.info('Loaded ${_products.length} products', tag: 'IAP');
    } catch (e, stack) {
      AppLogger.error('Exception querying products', tag: 'IAP', error: e);
      AppLogger.debug('Stack trace: $stack', tag: 'IAP');
    }
  }

  /// Extract the store product ID from a full product ID
  ///
  /// If the ID contains a colon (e.g., "get_gains.premium:premium-subscription"),
  /// returns only the part before the colon (e.g., "get_gains.premium").
  /// Otherwise returns the ID as-is.
  String _extractStoreProductId(String fullProductId) {
    final colonIndex = fullProductId.indexOf(':');
    if (colonIndex > 0) {
      return fullProductId.substring(0, colonIndex);
    }
    return fullProductId;
  }

  /// Get a loaded product by ID (handles full product:basePlan format)
  ProductDetails? getProduct(String productId) {
    // First try direct lookup
    var product = _products[productId];
    if (product != null) return product;

    // Try mapping to store product ID
    final storeId =
        _productIdMapping[productId] ?? _extractStoreProductId(productId);
    return _products[storeId];
  }

  /// Get all loaded products
  List<ProductDetails> get products => _products.values.toList();

  /// Purchase a product
  ///
  /// [productId] - The product ID to purchase (can be full "product:basePlan" format)
  /// Returns a PurchaseResult with the status and details
  Future<PurchaseResult> purchaseProduct(String productId) async {
    if (!_isAvailable) {
      return const PurchaseResult(
        status: PurchaseState.error,
        errorMessage: 'Store is not available',
      );
    }

    // Get product using the mapping (handles full product:basePlan format)
    final product = getProduct(productId);
    if (product == null) {
      // Log debug info to help diagnose the issue
      final storeId =
          _productIdMapping[productId] ?? _extractStoreProductId(productId);
      AppLogger.error(
        'Product not found: $productId (storeId: $storeId)',
        tag: 'IAP',
      );
      AppLogger.debug(
        'Loaded products: ${_products.keys.toList()}, Mapping: $_productIdMapping',
        tag: 'IAP',
      );
      return PurchaseResult(
        status: PurchaseState.error,
        errorMessage:
            'Product not found: $productId. Store may not be ready or product is not available.',
      );
    }

    AppLogger.debug('Initiating purchase for: ${product.id}', tag: 'IAP');

    try {
      late final PurchaseParam purchaseParam;

      // Handle Android subscriptions with GooglePlayPurchaseParam
      if (Platform.isAndroid && product is GooglePlayProductDetails) {
        // For subscriptions, we must pass the offerToken to specify which base plan/offer
        final offerToken = product.offerToken;
        AppLogger.debug(
          'Using GooglePlayPurchaseParam for Android subscription (offerToken: $offerToken)',
          tag: 'IAP',
        );
        purchaseParam = GooglePlayPurchaseParam(
          productDetails: product,
          offerToken: offerToken,
        );
      } else {
        // Non-Android or non-Google Play product
        purchaseParam = PurchaseParam(productDetails: product);
      }

      final success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (!success) {
        return const PurchaseResult(
          status: PurchaseState.error,
          errorMessage: 'Failed to initiate purchase',
        );
      }

      // The actual result will come through the purchase stream
      // Return purchasing status - caller should listen to purchaseResults
      return const PurchaseResult(status: PurchaseState.purchasing);
    } catch (e) {
      AppLogger.error('Purchase error', tag: 'IAP', error: e);
      return PurchaseResult(
        status: PurchaseState.error,
        errorMessage: 'Purchase error: $e',
      );
    }
  }

  /// Handle purchase updates from the stream
  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      AppLogger.debug(
        'Purchase update: ${purchase.productID} - ${purchase.status}',
        tag: 'IAP',
      );

      switch (purchase.status) {
        case PurchaseStatus.pending:
          _purchaseController.add(
            PurchaseResult(
              status: PurchaseState.pending,
              purchaseDetails: purchase,
            ),
          );
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // Complete the purchase on the platform
          if (purchase.pendingCompletePurchase) {
            _inAppPurchase.completePurchase(purchase);
          }
          _purchaseController.add(
            PurchaseResult(
              status: PurchaseState.completed,
              purchaseDetails: purchase,
            ),
          );
          break;

        case PurchaseStatus.error:
          _purchaseController.add(
            PurchaseResult(
              status: PurchaseState.error,
              purchaseDetails: purchase,
              errorMessage: purchase.error?.message ?? 'Purchase failed',
            ),
          );
          break;

        case PurchaseStatus.canceled:
          _purchaseController.add(
            PurchaseResult(
              status: PurchaseState.canceled,
              purchaseDetails: purchase,
            ),
          );
          break;
      }
    }
  }

  /// Restore previous purchases
  ///
  /// Useful for when user reinstalls or switches devices.
  /// Returns stream of restored purchases through purchaseResults.
  Future<void> restorePurchases() async {
    if (!_isAvailable) {
      AppLogger.warning('Cannot restore - store not available', tag: 'IAP');
      return;
    }

    AppLogger.debug('Restoring purchases', tag: 'IAP');
    await _inAppPurchase.restorePurchases();
  }

  /// Get the purchase token from a purchase
  ///
  /// Platform-specific extraction of the purchase token/receipt.
  String? getPurchaseToken(PurchaseDetails purchase) {
    if (Platform.isAndroid) {
      // For Android, the verificationData contains the purchase token
      return purchase.verificationData.serverVerificationData;
    } else if (Platform.isIOS) {
      // For iOS, use the receipt data
      return purchase.verificationData.serverVerificationData;
    }
    return null;
  }

  /// Get the payment provider for the current platform
  PaymentProvider get currentProvider {
    // Currently only supporting Google Play
    // Add Apple when iOS is implemented
    return PaymentProvider.googlePay;
  }

  /// Dispose the service
  void dispose() {
    AppLogger.debug('Disposing InAppPurchaseService', tag: 'IAP');
    _subscription?.cancel();
    _purchaseController.close();
  }
}

/// In-App Purchase Service Provider
@Riverpod(keepAlive: true)
InAppPurchaseService inAppPurchaseService(Ref ref) {
  final service = InAppPurchaseService();
  ref.onDispose(service.dispose);
  return service;
}
