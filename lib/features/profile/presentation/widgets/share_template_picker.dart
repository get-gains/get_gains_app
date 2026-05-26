import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/profile_stats_model.dart';
import '../../../auth/data/models/user_model.dart';
import 'share_stats_card.dart';
import 'share_service.dart';

class ShareTemplatePicker extends StatelessWidget {
  const ShareTemplatePicker({
    super.key,
    required this.stats,
    required this.user,
    this.avatarUrl,
  });

  final ProfileStatsModel stats;
  final UserModel user;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Share your stats',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTextStyles.fontFamilySans,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose a template to share',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    fontFamily: AppTextStyles.fontFamilySans,
                  ),
            ),
            const SizedBox(height: 20),
            _TemplateOption(
              template: ShareStatTemplate.weeklyWarrior,
              stats: stats,
              isDark: isDark,
              onTap: () => _openPreview(context, ShareStatTemplate.weeklyWarrior),
            ),
            const SizedBox(height: 12),
            _TemplateOption(
              template: ShareStatTemplate.setMachine,
              stats: stats,
              isDark: isDark,
              onTap: () => _openPreview(context, ShareStatTemplate.setMachine),
            ),
            const SizedBox(height: 12),
            _TemplateOption(
              template: ShareStatTemplate.dailyGrind,
              stats: stats,
              isDark: isDark,
              onTap: () => _openPreview(context, ShareStatTemplate.dailyGrind),
            ),
            const SizedBox(height: 12),
            _TemplateOption(
              template: ShareStatTemplate.onFire,
              stats: stats,
              isDark: isDark,
              onTap: () => _openPreview(context, ShareStatTemplate.onFire),
            ),
          ],
        ),
      ),
    );
  }

  void _openPreview(BuildContext context, ShareStatTemplate template) {
    final repaintKey = GlobalKey();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShareCardPreview(
          template: template,
          stats: stats,
          user: user,
          avatarUrl: avatarUrl,
          repaintKey: repaintKey,
        ),
      ),
    );
  }
}

class _TemplateOption extends StatelessWidget {
  const _TemplateOption({
    required this.template,
    required this.stats,
    required this.isDark,
    required this.onTap,
  });

  final ShareStatTemplate template;
  final ProfileStatsModel stats;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (statValue, statLabel) = _templatePreview();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                _templateIcon(),
                color: AppColors.primaryDark,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontFamily: AppTextStyles.fontFamilySans,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    statLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          fontFamily: AppTextStyles.fontFamilySans,
                        ),
                  ),
                ],
              ),
            ),
            Text(
              statValue,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamilyMono,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _templateIcon() {
    return switch (template) {
      ShareStatTemplate.weeklyWarrior => Icons.fitness_center_outlined,
      ShareStatTemplate.setMachine => Icons.repeat,
      ShareStatTemplate.dailyGrind => Icons.today_outlined,
      ShareStatTemplate.onFire => Icons.local_fire_department_outlined,
    };
  }

  (String value, String label) _templatePreview() {
    return switch (template) {
      ShareStatTemplate.weeklyWarrior => (
          '${stats.workoutsThisWeek}',
          'workouts this week',
        ),
      ShareStatTemplate.setMachine => (
          '${stats.setsToday}',
          'sets today',
        ),
      ShareStatTemplate.dailyGrind => (
          stats.completedToday ? 'Done' : '—',
          stats.completedToday ? 'completed today' : 'not yet',
        ),
      ShareStatTemplate.onFire => (
          '${stats.streakDays}',
          'day streak',
        ),
    };
  }
}
