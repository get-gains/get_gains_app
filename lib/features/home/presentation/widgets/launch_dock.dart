// lib/features/home/presentation/widgets/launch_dock.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/router_provider.dart';

/// Horizontal-scrolling pill row of compact navigation shortcuts.
///
/// Client: Shop, Wardrobe, Leaderboard, History, Missions, Library.
/// Coach: Shop, Leaderboard, History, Missions, Library (no Wardrobe).
///
/// @param dockKey [GlobalKey] forwarded for tour anchoring.
/// @param isCoach When true, omits the Wardrobe pill.
class LaunchDock extends StatelessWidget {
  const LaunchDock({super.key, this.dockKey, required this.isCoach});

  final GlobalKey? dockKey;
  final bool isCoach;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = _items(context, isCoach);

    Widget dock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Quick Launch',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _LaunchPill(item: items[i], isDark: isDark),
          ),
        ),
      ],
    );

    if (dockKey != null) {
      dock = KeyedSubtree(key: dockKey, child: dock);
    }

    return dock;
  }

  List<_DockItem> _items(BuildContext context, bool isCoach) {
    return [
      _DockItem(
        icon: Icons.storefront_rounded,
        label: 'Shop',
        color: const Color(0xFFFFD700),
        onTap: () => context.push(AppRoutes.shop),
      ),
      if (!isCoach)
        _DockItem(
          icon: Icons.checkroom_rounded,
          label: 'Wardrobe',
          color: const Color(0xFF8B5CF6),
          onTap: () => context.push(AppRoutes.inventory),
        ),
      _DockItem(
        icon: Icons.leaderboard_rounded,
        label: 'Leaderboard',
        color: const Color(0xFF3B82F6),
        onTap: () => context.push(AppRoutes.leaderboard),
      ),
      _DockItem(
        icon: Icons.history,
        label: 'History',
        color: AppColors.primaryDark,
        onTap: () => context.push(AppRoutes.workoutHistory),
      ),
      _DockItem(
        icon: Icons.flag_rounded,
        label: 'Missions',
        color: const Color(0xFFF59E0B),
        onTap: () => context.push(AppRoutes.missions),
      ),
      _DockItem(
        icon: Icons.border_all_rounded,
        label: 'Library',
        color: const Color(0xFF22C55E),
        onTap: () => context.push(AppRoutes.formLibrary),
      ),
    ];
  }
}

class _DockItem {
  const _DockItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

class _LaunchPill extends StatelessWidget {
  const _LaunchPill({required this.item, required this.isDark});

  final _DockItem item;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 150,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: item.color, size: 20),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                item.label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
