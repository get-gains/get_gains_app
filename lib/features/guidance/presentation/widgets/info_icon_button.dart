import 'package:flutter/material.dart';

import '../../data/models/help_content_model.dart';
import 'contextual_help_sheet.dart';

/// Reusable AppBar action that shows contextual help.
///
/// When tapped, it either calls [onTapOverride] (e.g. to re-trigger a tour)
/// or opens a [ContextualHelpSheet] in a modal bottom sheet.
///
/// ```dart
/// AppBar(
///   actions: [
///     InfoIconButton(content: kRoutineDetailHelp),
///   ],
/// )
/// ```
class InfoIconButton extends StatelessWidget {
  const InfoIconButton({
    super.key,
    required this.content,
    this.onTapOverride,
    this.iconSize = 24.0,
    this.color,
  });

  /// Help content to display in the bottom sheet.
  final HelpContentModel content;

  /// When provided, called instead of showing the bottom sheet.
  /// Useful for re-triggering a spotlight tour from the info icon.
  final VoidCallback? onTapOverride;

  /// Size of the help icon.
  final double iconSize;

  /// Optional color override for the icon.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.help_outline, size: iconSize, color: color),
      tooltip: 'Help',
      onPressed: () {
        if (onTapOverride != null) {
          onTapOverride!();
          return;
        }
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => ContextualHelpSheet(content: content),
        );
      },
    );
  }
}
