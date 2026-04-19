class RevenueCatConfig {
  RevenueCatConfig._();

  static const String androidApiKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
  );

  static const String iosApiKey = String.fromEnvironment(
    'REVENUECAT_IOS_API_KEY',
  );

  static const String entitlementId = 'premium';
}
