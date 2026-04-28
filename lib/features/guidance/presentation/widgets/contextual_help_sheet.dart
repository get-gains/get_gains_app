import 'package:flutter/material.dart';

import '../../data/models/help_content_model.dart';

/// Maps [HelpSection.iconName] strings to Material [IconData].
///
/// Falls back to [Icons.info_outline] for unknown names.
IconData _resolveIcon(String name) {
  const map = <String, IconData>{
    'fitness_center': Icons.fitness_center,
    'analytics': Icons.analytics_outlined,
    'play_arrow': Icons.play_arrow,
    'stop': Icons.stop,
    'visibility': Icons.visibility,
    'threed_rotation': Icons.threed_rotation,
    'do_not_disturb_on': Icons.do_not_disturb_on,
    'timer': Icons.timer_outlined,
    'score': Icons.score,
    'auto_awesome': Icons.auto_awesome,
    'help': Icons.help_outline,
    'lightbulb': Icons.lightbulb_outline,
    'info': Icons.info_outline,
    'trending_up': Icons.trending_up,
    'star': Icons.star_outline,
    'repeat': Icons.repeat,
    'target': Icons.gps_fixed,
    'speed': Icons.speed,
    'camera': Icons.camera_alt_outlined,
    'history': Icons.history,
    'dashboard': Icons.dashboard_outlined,
    'check_circle': Icons.check_circle_outline,
    'warning': Icons.warning_amber_outlined,
  };
  return map[name] ?? Icons.info_outline;
}

/// Content widget for a modal bottom sheet showing contextual help.
///
/// Displays the [HelpContentModel]'s title and each [HelpSection] in order.
/// Designed to be used with [showModalBottomSheet]:
///
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   showDragHandle: true,
///   builder: (_) => ContextualHelpSheet(content: kRoutineDetailHelp),
/// );
/// ```
class ContextualHelpSheet extends StatelessWidget {
  const ContextualHelpSheet({super.key, required this.content});

  final HelpContentModel content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.75,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                content.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Scrollable sections
              Expanded(
                child: ListView.separated(
                  itemCount: content.sections.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final section = content.sections[index];
                    return _HelpSectionWidget(section: section);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpSectionWidget extends StatelessWidget {
  const _HelpSectionWidget({required this.section});

  final HelpSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.heading != null) ...[
          Row(
            children: [
              if (section.iconName != null) ...[
                Icon(
                  _resolveIcon(section.iconName!),
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  section.heading!,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        Text(section.body, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
