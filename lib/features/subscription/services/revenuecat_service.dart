import 'dart:io';

import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/revenuecat_config.dart';
import '../../../core/utils/logger.dart';

part 'revenuecat_service.g.dart';

@Riverpod(keepAlive: true)
RevenueCatService revenueCatService(Ref ref) {
  return RevenueCatService();
}

class RevenueCatService {
  static const String _tag = 'RevenueCatService';

  /// Static so the flag is shared across all instances (main() creates one,
  /// Riverpod provider creates another).
  static bool _isConfigured = false;

  /// Initialize RevenueCat SDK. Call once at app start.
  Future<void> init() async {
    if (_isConfigured) return;

    final apiKey = Platform.isIOS
        ? RevenueCatConfig.iosApiKey
        : RevenueCatConfig.androidApiKey;

    if (apiKey.isEmpty) {
      AppLogger.warning(
        'RevenueCat API key not set — SDK not configured',
        tag: _tag,
      );
      return;
    }

    final configuration = PurchasesConfiguration(apiKey);
    await Purchases.configure(configuration);
    _isConfigured = true;
    AppLogger.info('RevenueCat SDK configured', tag: _tag);
  }

  /// Alias RC app_user_id to supabase_auth_id.
  /// Fire-and-forget — caller should not await.
  Future<void> login(String supabaseAuthId) async {
    if (!_isConfigured) return;

    try {
      final result = await Purchases.logIn(supabaseAuthId);
      AppLogger.info('RevenueCat login: created=${result.created}', tag: _tag);
    } catch (e) {
      AppLogger.error('RevenueCat login failed', tag: _tag, error: e);
    }
  }

  /// Reset RC to anonymous user on app logout.
  Future<void> logout() async {
    if (!_isConfigured) return;

    try {
      await Purchases.logOut();
      AppLogger.info('RevenueCat logged out', tag: _tag);
    } catch (e) {
      AppLogger.error('RevenueCat logout failed', tag: _tag, error: e);
    }
  }

  /// Get current RC offerings.
  Future<Offerings> getOfferings() async {
    return Purchases.getOfferings();
  }

  /// Purchase a package. Returns [CustomerInfo] on success.
  /// Throws [PlatformException] on cancel/error.
  Future<CustomerInfo> purchase(Package package) async {
    final params = PurchaseParams.package(package);
    final result = await Purchases.purchase(params);
    return result.customerInfo;
  }

  /// Purchase a specific subscription option (e.g. a discounted Google Play
  /// offer identified by tag). Returns [CustomerInfo] on success.
  Future<CustomerInfo> purchaseSubscriptionOption(SubscriptionOption option) async {
    final params = PurchaseParams.subscriptionOption(option);
    final result = await Purchases.purchase(params);
    return result.customerInfo;
  }

  /// Restore purchases for the current user.
  Future<CustomerInfo> restorePurchases() async {
    return Purchases.restorePurchases();
  }

  /// Get current customer info.
  Future<CustomerInfo> getCustomerInfo() async {
    return Purchases.getCustomerInfo();
  }

  /// Check if the premium entitlement is active.
  bool isEntitlementActive(CustomerInfo info) {
    return info.entitlements.active.containsKey(RevenueCatConfig.entitlementId);
  }
}
