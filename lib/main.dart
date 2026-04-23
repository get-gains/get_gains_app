import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

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

  // Wait for platform channels to be fully ready before using path_provider
  // This is necessary because plugins like flutter_embed_unity can delay channel initialization
  await _waitForPlatformChannels();

  // Initialize Hive for user preferences
  final userPrefsBox = await _initWithRetry(
    () => UserPreferencesService.init(),
    maxRetries: 5,
    initialDelay: const Duration(milliseconds: 300),
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

/// Waits for platform channels to be fully ready.
///
/// Some plugins (like flutter_embed_unity) register channels asynchronously after
/// the Flutter engine starts. This function polls path_provider until it responds,
/// ensuring all platform channels are ready before proceeding with initialization.
Future<void> _waitForPlatformChannels() async {
  const maxAttempts = 10;
  const initialDelay = Duration(milliseconds: 100);

  for (var i = 0; i < maxAttempts; i++) {
    try {
      // Try to use path_provider as a canary for platform channel readiness
      await getApplicationDocumentsDirectory();
      AppLogger.info(
        'Platform channels ready after ${i + 1} attempt(s)',
        tag: 'Main',
      );
      return;
    } on PlatformException catch (_) {
      if (i == maxAttempts - 1) {
        // Let the retry wrapper handle final failures
        AppLogger.warning(
          'Platform channels not ready after $maxAttempts attempts, proceeding anyway',
          tag: 'Main',
        );
        return;
      }

      // Exponential backoff: 100ms, 200ms, 400ms, ...
      final delayMs = initialDelay.inMilliseconds * (1 << i);
      await Future.delayed(Duration(milliseconds: delayMs));
    }
  }
}

/// Retry helper for platform channel initialization during hot restart.
/// Platform channels can become disconnected during hot restart, requiring a retry.
/// Uses exponential backoff to allow more time for platform channels to initialize.
Future<T> _initWithRetry<T>(
  Future<T> Function() init, {
  int maxRetries = 5,
  Duration initialDelay = const Duration(milliseconds: 300),
}) async {
  for (var i = 0; i < maxRetries; i++) {
    try {
      return await init();
    } catch (e) {
      if (i == maxRetries - 1) rethrow;

      // Exponential backoff: 300ms, 600ms, 1200ms, 2400ms, 4800ms
      final delayMs = initialDelay.inMilliseconds * (1 << i);
      final currentDelay = Duration(milliseconds: delayMs);

      AppLogger.warning(
        'Platform channel init failed (attempt ${i + 1}/$maxRetries): $e',
        tag: 'Main',
      );

      await Future.delayed(currentDelay);
    }
  }
  throw StateError('Failed to initialize after $maxRetries attempts');
}
