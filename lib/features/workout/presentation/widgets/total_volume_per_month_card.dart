import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/monthly_insight_model.dart';
import '../../data/models/monthly_volume_model.dart';
import '../../logic/monthly_volume_logic.dart';
import '../../../home/presentation/providers/home_providers.dart';

/// Card showing monthly training volume: avg volume/session with trend,
/// a mini sparkline of 6 months, and confidence indicators.
///
/// Watches [monthlyInsightProvider]. Hides entirely on error.
/// Shows an empty state when the user has fewer than 3 sessions all-time.
class TotalVolumePerMonthCard extends ConsumerWidget {
  const TotalVolumePerMonthCard({super.key, this.onTap});

  /// Stub for future monthly detail screen navigation.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final secondaryText =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final accent = isDark ? AppColors.accentDark : const Color(0xFF22C55E);

    final insightAsync = ref.watch(monthlyInsightProvider);

    return insightAsync.when(
      data: (insight) {
        // All-time session check: need ≥3 across the 6-month window
        final allTimeSessions =
            insight.sparklineSessions.fold(0, (sum, s) => sum + s);
        if (allTimeSessions < 3) {
          return _EmptyVolumeState(isDark: isDark);
        }

        final monthlyVolumes = insight.sparklineVolumes.isNotEmpty
            ? MonthlyVolume.fromSparkline(insight)
            : <MonthlyVolume>[];

        if (monthlyVolumes.isEmpty) {
          return _EmptyVolumeState(isDark: isDark);
        }

        return _VolumeCard(
          insight: insight,
          monthlyVolumes: monthlyVolumes,
          primary: primary,
          secondaryText: secondaryText,
          accent: accent,
          isDark: isDark,
          onTap: onTap,
        );
      },
      loading: () => const _MonthlyLoadingSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _VolumeCard extends StatelessWidget {
  const _VolumeCard({
    required this.insight,
    required this.monthlyVolumes,
    required this.primary,
    required this.secondaryText,
    required this.accent,
    required this.isDark,
    this.onTap,
  });

  final MonthlyInsight insight;
  final List<MonthlyVolume> monthlyVolumes;
  final Color primary;
  final Color secondaryText;
  final Color accent;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final currentMonth = monthlyVolumes.isNotEmpty ? monthlyVolumes.last : null;
    final currentSessions = currentMonth?.sessionCount ?? 0;
    final lowConf = isLowConfidence(currentSessions);

    final barHeights = normalizeBarHeights(monthlyVolumes);
    final showPctPill = currentMonth != null
        ? shouldShowPercentChange(currentMonth.percentChangeVsPrevMonth)
        : false;

    final trendColor =
        (currentMonth?.percentChangeVsPrevMonth ?? 0) >= 0
            ? AppColors.success
            : AppColors.error;

    return Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header row ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.trending_up, color: primary, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Total volume / month',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: secondaryText),
                          ),
                        ],
                      ),
                      if (showPctPill && currentMonth != null)
                        _PctPill(
                          pct: currentMonth.percentChangeVsPrevMonth!,
                          color: trendColor,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ── Big stat ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatKg(insight.avgVolumePerSession),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '/session',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: secondaryText),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // ── Confidence subtitle ──
                  Row(
                    children: [
                      Text(
                        '$currentSessions session${currentSessions == 1 ? '' : 's'} this month',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: secondaryText),
                      ),
                      if (lowConf) ...[
                        const SizedBox(width: 4),
                        Text(
                          '· low confidence',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: secondaryText),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Mini bar sparkline ──
                  SizedBox(
                    height: 40,
                    child: CustomPaint(
                      size: const Size(double.infinity, 40),
                      painter: _SparklinePainter(
                        heights: barHeights,
                        primary: primary,
                        neutralColor: isDark
                            ? AppColors.surface2Dark
                            : AppColors.surface2Light,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}

/// Percent-change pill — green or red background with white/colored text.
class _PctPill extends StatelessWidget {
  const _PctPill({required this.pct, required this.color});

  final double pct;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final sign = pct >= 0 ? '+' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$sign${pct.round()}%',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

/// CustomPainter for the 6-month sparkline bars.
///
/// Left → right = oldest → newest. Rightmost bar is primary-filled;
/// all others use a neutral gray. Heights come from [heights] (0.05–1.0
/// fractions of the 40 px bar area).
class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({
    required this.heights,
    required this.primary,
    required this.neutralColor,
  });

  final List<double> heights;
  final Color primary;
  final Color neutralColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (heights.isEmpty) return;

    final barCount = heights.length;
    const gap = 3.0;
    final totalGaps = gap * (barCount - 1);
    final barWidth = (size.width - totalGaps) / barCount;

    for (int i = 0; i < barCount; i++) {
      final barHeight = heights[i] * size.height;
      final isCurrentMonth = i == barCount - 1;

      final x = i * (barWidth + gap);
      final y = size.height - barHeight;

      final paint = Paint()
        ..color = isCurrentMonth ? primary : neutralColor
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          topLeft: const Radius.circular(2),
          topRight: const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      heights != oldDelegate.heights ||
      primary != oldDelegate.primary ||
      neutralColor != oldDelegate.neutralColor;
}

class _EmptyVolumeState extends StatelessWidget {
  const _EmptyVolumeState({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: AppCard(
        padding: const EdgeInsets.all(20),
        child: AppEmptyState.compact(
          icon: Icons.fitness_center,
          title: 'No volume trend yet',
          description:
              'Log a few more workouts to see how your training load changes over time.',
        ),
      ),
    );
  }
}

class _MonthlyLoadingSkeleton extends StatelessWidget {
  const _MonthlyLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final skeletonColor =
        isDark ? AppColors.surface2Dark : AppColors.surface2Light;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row placeholder
            Row(
              children: [
                Container(
                  width: 120,
                  height: 14,
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Big stat placeholder
            Container(
              width: 160,
              height: 28,
              decoration: BoxDecoration(
                color: skeletonColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            // Subtitle placeholder
            Container(
              width: 140,
              height: 12,
              decoration: BoxDecoration(
                color: skeletonColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            // Sparkline placeholder — 6 bars
            Row(
              children: List.generate(6, (i) {
                final heights = [20.0, 16.0, 24.0, 28.0, 32.0, 36.0];
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 5 ? 3 : 0),
                    child: Container(
                      height: heights[i],
                      decoration: BoxDecoration(
                        color: skeletonColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(2),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
