import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/core.dart';
import 'providers/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize any services that need early setup here
  // Example: await Firebase.initializeApp();

  AppLogger.info('Starting Get Gains App', tag: 'Main');

  runApp(const ProviderScope(child: GetGainsApp()));
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
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,

      // Router configuration
      routerConfig: router,
    );
  }
}
