import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../providers/router_provider.dart';

/// Coach Programs List Screen
///
/// @deprecated The global program list is dead — programs are now per-client.
/// This placeholder redirects to the routine-templates library.
/// Will be deleted in Phase 4.
class CoachProgramsScreen extends ConsumerWidget {
  const CoachProgramsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Redirect to routine templates — global program list is dead.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) context.go(AppRoutes.coachRoutines);
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Programs')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
