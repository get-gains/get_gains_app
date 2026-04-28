import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../data/coin_estimate_calculator.dart';
import '../../data/models/coin_estimate_model.dart';
import '../providers/coin_balance_provider.dart';
import '../widgets/coin_breakdown_card.dart';

/// Coin Reward Screen
///
/// Shown after a workout session completes. Displays:
/// - Animated coin total headline
/// - Detailed breakdown card (sets, accuracy, bonuses)
/// - Pending/confirmed state indicator
/// - "Continue" button → navigates home
///
/// Receives session stats via route extras and computes
/// a local estimate. If the sync has already completed, the
/// server-confirmed data is used instead.
class CoinRewardScreen extends ConsumerStatefulWidget {
  const CoinRewardScreen({
    super.key,
    required this.setsCompleted,
    required this.sessionDurationMin,
    this.avgAccuracy = 1.0,
    this.streakDays = 0,
    this.showWorkoutSummaryAfterContinue = false,
    this.workoutSummary,
  });

  final int setsCompleted;
  final int sessionDurationMin;
  final double avgAccuracy;
  final int streakDays;
  final bool showWorkoutSummaryAfterContinue;
  final Map<String, dynamic>? workoutSummary;

  @override
  ConsumerState<CoinRewardScreen> createState() => _CoinRewardScreenState();
}

class _CoinRewardScreenState extends ConsumerState<CoinRewardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final CoinEstimateModel _estimate;

  @override
  void initState() {
    super.initState();

    _estimate = CoinEstimateCalculator.estimate(
      setsCompleted: widget.setsCompleted,
      sessionDurationMin: widget.sessionDurationMin,
      avgAccuracy: widget.avgAccuracy,
      streakDays: widget.streakDays,
    );

    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    // Trigger animation after frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animController.forward();
    });

    // Refresh coin balance from server after arriving here
    Future.microtask(() {
      ref.read(coinBalanceProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final coinColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: AppTheme.screenPadding,
          child: Column(
            children: [
              const Spacer(flex: 1),

              // ── Animated coin headline ──
              ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  children: [
                    Icon(
                      Icons.monetization_on_rounded,
                      color: coinColor,
                      size: 72,
                    ),
                    const SizedBox(height: AppTheme.spacing3),
                    Text(
                      'Workout Complete!',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: isDark
                            ? AppColors.foregroundDark
                            : AppColors.foregroundLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing2),
                    Text(
                      'You earned coins for this session',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForegroundLight,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spacing8),

              // ── Breakdown card (fades in) ──
              FadeTransition(
                opacity: _fadeAnimation,
                child: CoinBreakdownCard.fromEstimate(_estimate),
              ),

              const Spacer(flex: 2),

              // ── Continue button ──
              FadeTransition(
                opacity: _fadeAnimation,
                child: SizedBox(
                  width: double.infinity,
                  child: AppButton.primary(
                    label: 'Continue',
                    onPressed: _handleContinue,
                    isFullWidth: true,
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spacing4),
            ],
          ),
        ),
      ),
    );
  }

  void _handleContinue() {
    context.go(AppRoutes.home);

    if (!widget.showWorkoutSummaryAfterContinue) return;
    final summary = widget.workoutSummary;
    if (summary == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dialogContext = appNavigatorKey.currentContext;
      if (dialogContext == null) return;

      final exerciseStatuses =
          (summary['exerciseStatuses'] as List<dynamic>? ?? const [])
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();

      showDialog(
        context: dialogContext,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Workout Complete!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Duration: ${summary['durationText'] ?? '--:--'}'),
              Text('Sets completed: ${summary['setsCompleted'] ?? 0}'),
              Text(
                'Total volume: ${((summary['totalVolumeKg'] as num?) ?? 0).toStringAsFixed(1)} kg',
              ),
              if (exerciseStatuses.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                ...exerciseStatuses.map((exercise) {
                  final completed =
                      (exercise['completed'] as num?)?.toInt() ?? 0;
                  final target = (exercise['target'] as num?)?.toInt() ?? 0;
                  final done = completed >= target && target > 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          done
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: done ? AppColors.success : Colors.grey,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            exercise['name'] as String? ?? 'Exercise',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          '$completed/$target',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: done ? AppColors.success : Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    });
  }
}
