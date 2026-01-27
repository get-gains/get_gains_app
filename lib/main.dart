import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/core.dart';
import 'providers/providers.dart';
import 'widgets/widgets.dart';

/// Provider for SharedPreferences instance
/// Must be overridden in main() with the actual instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized in main()');
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize SharedPreferences early to avoid channel errors
  final sharedPrefs = await SharedPreferences.getInstance();

  AppLogger.info('Starting Get Gains App', tag: 'Main');

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(sharedPrefs)],
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
