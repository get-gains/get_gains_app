import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/core.dart';
import 'features/auth/services/user_preferences_service.dart';
import 'providers/providers.dart';
import 'widgets/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Hive for user preferences
  // Retry logic handles hot restart channel disconnection issues
  final userPrefsBox = await _initWithRetry(
    () => UserPreferencesService.init(),
    maxRetries: 3,
    delay: const Duration(milliseconds: 100),
  );

  AppLogger.info('Starting Get Gains App', tag: 'Main');

  runApp(
    ProviderScope(
      overrides: [userPrefsBoxProvider.overrideWithValue(userPrefsBox)],
      child: const GetGainsApp(),
    ),
  );
}

/// Root Application Widget
class GetGainsApp extends ConsumerWidget {
  const GetGainsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,

      // Toast overlay wrapper
      builder: (context, child) => AppToastOverlay(child: child!),

      // Router configuration
      routerConfig: router,
    );
  }
}

/// Retry helper for platform channel initialization during hot restart.
/// Platform channels can become disconnected during hot restart, requiring a retry.
Future<T> _initWithRetry<T>(
  Future<T> Function() init, {
  int maxRetries = 3,
  Duration delay = const Duration(milliseconds: 100),
}) async {
  for (var i = 0; i < maxRetries; i++) {
    try {
      return await init();
    } on PlatformException catch (e) {
      if (i == maxRetries - 1) rethrow;
      AppLogger.warning(
        'Platform channel init failed (attempt ${i + 1}/$maxRetries): ${e.message}',
        tag: 'Main',
      );
      await Future.delayed(delay);
    }
  }
  throw StateError('Failed to initialize after $maxRetries attempts');
}
