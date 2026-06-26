// lib/features/home/presentation/widgets/coach_tools_block.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';

/// 2×2 mini-grid of quick-access coach tool tiles.
///
/// Each tool tile accepts an optional [GlobalKey] for the coach spotlight tour.
class CoachToolsBlock extends StatelessWidget {
  const CoachToolsBlock({
    super.key,
    this.routinesKey,
    this.exercisesKey,
    this.clientsKey,
    this.settingsKey,
  });

  final GlobalKey? routinesKey;
  final GlobalKey? exercisesKey;
  final GlobalKey? clientsKey;
  final GlobalKey? settingsKey;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Coach Tools',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ToolTile(
                  key: routinesKey,
                  icon: Icons.assignment_outlined,
                  label: 'Routines',
                  color: const Color(0xFF3B82F6),
                  isDark: isDark,
                  onTap: () => context.push(AppRoutes.coachRoutines),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ToolTile(
                  key: exercisesKey,
                  icon: Icons.fitness_center_outlined,
                  label: 'Exercises',
                  color: const Color(0xFF8B5CF6),
                  isDark: isDark,
                  onTap: () => context.push(AppRoutes.coachExercises),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ToolTile(
                  key: clientsKey,
                  icon: Icons.people_outlined,
                  label: 'Clients',
                  color: AppColors.coach,
                  isDark: isDark,
                  onTap: () => context.push(AppRoutes.coachRoster),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ToolTile(
                  key: settingsKey,
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  color: AppColors.gray500,
                  isDark: isDark,
                  onTap: () => context.push(AppRoutes.coachSettings),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard.interactive(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
