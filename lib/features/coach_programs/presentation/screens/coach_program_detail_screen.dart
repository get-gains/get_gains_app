import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Coach Program Detail Screen
///
/// @deprecated Replaced by the program builder wizard (Phase 3).
/// This placeholder shows a "redirecting" message until Phase 4 cleanup.
class CoachProgramDetailScreen extends ConsumerWidget {
  const CoachProgramDetailScreen({super.key, required this.programId});

  final String programId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Program Detail'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: const Center(
        child: Text(
          'This screen has been replaced by the Program Builder wizard.\n'
          'Use the client assignments screen instead.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
