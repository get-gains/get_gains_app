import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../widgets/widgets.dart';

/// Shows a bottom sheet to assign a routine to a program day-slot.
///
/// @deprecated Replaced by the program builder wizard (Phase 3).
/// This sheet is a no-op placeholder until Phase 4 cleanup removes it.
Future<bool?> showAssignRoutineSheet({
  required BuildContext context,
  required String programId,
  required List<int> existingDayNumbers,
}) async {
  return showAppBottomSheet<bool>(
    context: context,
    builder: (context) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline, size: 48),
          const SizedBox(height: 12),
          const Text(
            'This flow has been replaced by the Program Builder wizard.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Close'),
          ),
        ],
      ),
    ),
  );
}
