import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Create / Edit Program Form Screen
///
/// @deprecated Replaced by the program builder wizard (Phase 3).
/// This placeholder is kept for route compatibility until Phase 4 cleanup.
class CoachProgramFormScreen extends ConsumerWidget {
  const CoachProgramFormScreen({super.key, this.programId});

  final String? programId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Program Form'),
        leading: IconButton(
          icon: const Icon(Icons.close),
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
