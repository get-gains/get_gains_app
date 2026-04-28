import 'package:flutter/services.dart';

import 'package:purchases_flutter/purchases_flutter.dart';

/// Maps RevenueCat errors to user-friendly messages.
///
/// Replaces the old `BillingErrorParser` which was Google Play-specific.
class RevenueCatErrorMapper {
  RevenueCatErrorMapper._();

  /// Map an exception from a RevenueCat purchase to a user-facing message.
  static String mapError(Exception e) {
    if (e is PlatformException) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      return _mapErrorCode(code);
    }
    return 'An unexpected error occurred. Please try again.';
  }

  /// Check if the exception represents a user-initiated cancellation.
  static bool isUserCanceled(Exception e) {
    if (e is PlatformException) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      return code == PurchasesErrorCode.purchaseCancelledError;
    }
    return false;
  }

  static String _mapErrorCode(PurchasesErrorCode code) {
    switch (code) {
      case PurchasesErrorCode.purchaseCancelledError:
        return 'Purchase was canceled.';
      case PurchasesErrorCode.productAlreadyPurchasedError:
        return 'You already own this subscription. Tap "Restore Purchases" to restore it.';
      case PurchasesErrorCode.networkError:
        return 'Network error. Please check your connection and try again.';
      case PurchasesErrorCode.purchaseNotAllowedError:
        return 'Purchases are not allowed on this device.';
      case PurchasesErrorCode.purchaseInvalidError:
        return 'This purchase is invalid. Please try again.';
      case PurchasesErrorCode.storeProblemError:
        return 'There was a problem with the app store. Please try again later.';
      case PurchasesErrorCode.paymentPendingError:
        return 'Your payment is being processed. This may take a moment.';
      case PurchasesErrorCode.receiptAlreadyInUseError:
        return 'This receipt is already in use by another account.';
      default:
        return 'Something went wrong with your purchase. Please try again.';
    }
  }
}
