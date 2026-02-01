// lib/features/subscription/services/in_app_purchase_service.dart

import 'dart:async';
import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';
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
      AppLogger.warning('Store is not available', tag: 'IAP');
      _isInitialized = true;
      return false;
    }

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
  /// [productIds] - Product IDs to query
  Future<void> loadProducts(List<String> productIds) async {
    if (!_isAvailable) {
      AppLogger.warning(
        'Cannot load products - store not available',
        tag: 'IAP',
      );
      return;
    }

    AppLogger.debug('Loading products: $productIds', tag: 'IAP');

    final response = await _inAppPurchase.queryProductDetails(
      productIds.toSet(),
    );

    if (response.notFoundIDs.isNotEmpty) {
      AppLogger.warning(
        'Products not found: ${response.notFoundIDs}',
        tag: 'IAP',
      );
    }

    if (response.error != null) {
      AppLogger.error('Error loading products: ${response.error}', tag: 'IAP');
      return;
    }

    _products.clear();
    for (final product in response.productDetails) {
      _products[product.id] = product;
    }

    AppLogger.info('Loaded ${_products.length} products', tag: 'IAP');
  }

  /// Get a loaded product by ID
  ProductDetails? getProduct(String productId) => _products[productId];

  /// Get all loaded products
  List<ProductDetails> get products => _products.values.toList();

  /// Purchase a product
  ///
  /// [productId] - The product ID to purchase
  /// Returns a PurchaseResult with the status and details
  Future<PurchaseResult> purchaseProduct(String productId) async {
    if (!_isAvailable) {
      return const PurchaseResult(
        status: PurchaseState.error,
        errorMessage: 'Store is not available',
      );
    }

    final product = _products[productId];
    if (product == null) {
      return PurchaseResult(
        status: PurchaseState.error,
        errorMessage: 'Product not found: $productId',
      );
    }

    AppLogger.debug('Initiating purchase for: $productId', tag: 'IAP');

    try {
      // All our products are subscriptions
      final purchaseParam = PurchaseParam(productDetails: product);

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
