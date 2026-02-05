// lib/features/subscription/services/billing_error_parser.dart

/// User-friendly error messages for billing responses
///
/// Google Play Billing error codes are mapped to user-friendly messages.
/// These codes come from BillingClient.BillingResponseCode.
///
/// Reference:
/// https://developer.android.com/reference/com/android/billingclient/api/BillingClient.BillingResponseCode
class BillingErrorParser {
  BillingErrorParser._();

  /// Google Play Billing response codes
  static const int serviceTimeout = -3;
  static const int featureNotSupported = -2;
  static const int serviceDisconnected = -1;
  static const int ok = 0;
  static const int userCanceled = 1;
  static const int serviceUnavailable = 2;
  static const int billingUnavailable = 3;
  static const int itemUnavailable = 4;
  static const int developerError = 5;
  static const int error = 6;
  static const int itemAlreadyOwned = 7;
  static const int itemNotOwned = 8;
  static const int networkError = 12;

  /// Maps billing response codes to user-friendly messages
  static final Map<int, String> _errorMessages = {
    serviceTimeout:
        'The service timed out. Please check your internet connection and try again.',
    featureNotSupported: 'This feature is not supported on your device.',
    serviceDisconnected:
        'Connection to Google Play was lost. Please try again.',
    userCanceled: 'Purchase was canceled.',
    serviceUnavailable:
        'Google Play is temporarily unavailable. Please try again later.',
    billingUnavailable:
        'Google Play Billing is not available. Please update your device.',
    itemUnavailable:
        'This subscription is not available for purchase at this time.',
    developerError:
        'There was an issue processing your purchase. Please try again.',
    error: 'An error occurred during the purchase. Please try again.',
    itemAlreadyOwned:
        'You already own this subscription. Please restore your purchase instead.',
    itemNotOwned: 'This item is not owned.',
    networkError:
        'Network error. Please check your internet connection and try again.',
  };

  /// Gets a user-friendly error message from a billing response code
  ///
  /// [responseCode] - The BillingResponseCode from Google Play
  /// Returns a user-friendly error message
  static String getErrorMessage(int responseCode) {
    return _errorMessages[responseCode] ??
        'An unexpected error occurred (code: $responseCode). Please try again.';
  }

  /// Parses an error message that may contain a billing response code
  ///
  /// Error messages from the in_app_purchase plugin often contain
  /// patterns like "BillingResponse 7" or error codes embedded in text.
  ///
  /// [errorMessage] - The raw error message
  /// Returns a user-friendly error message
  static String parseErrorMessage(String? errorMessage) {
    if (errorMessage == null || errorMessage.isEmpty) {
      return 'An unexpected error occurred. Please try again.';
    }

    // Check for known patterns
    final message = errorMessage.toLowerCase();

    // Pattern: "BillingResponse.itemAlreadyOwned" or similar
    if (message.contains('itemalreadyowned') ||
        message.contains('item_already_owned') ||
        message.contains('already owned')) {
      return _errorMessages[itemAlreadyOwned]!;
    }

    if (message.contains('usercanceled') ||
        message.contains('user_canceled') ||
        message.contains('cancelled') ||
        message.contains('canceled')) {
      return _errorMessages[userCanceled]!;
    }

    if (message.contains('networkerror') ||
        message.contains('network_error') ||
        message.contains('network error') ||
        message.contains('socketexception') ||
        message.contains('connection')) {
      return _errorMessages[networkError]!;
    }

    if (message.contains('serviceunavailable') ||
        message.contains('service_unavailable') ||
        message.contains('service unavailable')) {
      return _errorMessages[serviceUnavailable]!;
    }

    if (message.contains('itemunavailable') ||
        message.contains('item_unavailable') ||
        message.contains('item unavailable') ||
        message.contains('product not found')) {
      return _errorMessages[itemUnavailable]!;
    }

    if (message.contains('servicetimeout') ||
        message.contains('service_timeout') ||
        message.contains('timeout')) {
      return _errorMessages[serviceTimeout]!;
    }

    if (message.contains('billingresponse') ||
        message.contains('billing response')) {
      // Try to extract the response code
      final codeMatch = RegExp(r'(\d+)').firstMatch(message);
      if (codeMatch != null) {
        final code = int.tryParse(codeMatch.group(1) ?? '');
        if (code != null && _errorMessages.containsKey(code)) {
          return _errorMessages[code]!;
        }
      }
    }

    // If we can't parse it, return a cleaned-up version of the original
    // or a generic message if it's too technical
    if (message.contains('exception') ||
        message.contains('error:') ||
        message.contains('billingclient') ||
        message.length > 100) {
      return 'An error occurred during the purchase. Please try again.';
    }

    // Return the original message if it seems user-friendly
    return errorMessage;
  }

  /// Checks if the error indicates the user canceled the purchase
  ///
  /// This is useful for handling canceled purchases differently
  /// (e.g., not showing an error toast)
  static bool isUserCanceled(String? errorMessage) {
    if (errorMessage == null) return false;
    final message = errorMessage.toLowerCase();
    return message.contains('usercanceled') ||
        message.contains('user_canceled') ||
        message.contains('cancelled') ||
        message.contains('canceled by user');
  }

  /// Checks if the error indicates the item is already owned
  ///
  /// This is useful for prompting restore instead of purchase
  static bool isAlreadyOwned(String? errorMessage) {
    if (errorMessage == null) return false;
    final message = errorMessage.toLowerCase();
    return message.contains('itemalreadyowned') ||
        message.contains('item_already_owned') ||
        message.contains('already owned') ||
        message.contains('you already own');
  }

  /// Checks if the error is a network error
  ///
  /// This is useful for suggesting the user check their connection
  static bool isNetworkError(String? errorMessage) {
    if (errorMessage == null) return false;
    final message = errorMessage.toLowerCase();
    return message.contains('networkerror') ||
        message.contains('network_error') ||
        message.contains('network error') ||
        message.contains('socketexception') ||
        message.contains('connection') ||
        message.contains('timeout');
  }
}
