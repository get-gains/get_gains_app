import 'package:flutter_dotenv/flutter_dotenv.dart';

class RevenueCatConfig {
  RevenueCatConfig._();

  static String get androidApiKey =>
      dotenv.env['REVENUECAT_ANDROID_API_KEY'] ?? '';

  static String get iosApiKey => dotenv.env['REVENUECAT_IOS_API_KEY'] ?? '';

  static const String entitlementId = 'premium';
}
