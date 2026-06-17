import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/api_error_codes.dart';
import '../../../../core/errors/error_messages.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_error.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/coach_settings_model.dart';
import '../providers/coach_settings_provider.dart';

/// Coach Settings Screen (ML-5)
///
/// Allows a coach to manage their settings:
/// - `maxClients` — hard cap on active client count
/// - `acceptingClients` — manual on/off for new intake
/// - `isDiscoverable` — appear in public search results
///
/// Server enforces capacity via these settings when clients
/// attempt to subscribe (ML-5).
class CoachSettingsScreen extends ConsumerStatefulWidget {
  const CoachSettingsScreen({super.key});

  @override
  ConsumerState<CoachSettingsScreen> createState() =>
      _CoachSettingsScreenState();
}

class _CoachSettingsScreenState extends ConsumerState<CoachSettingsScreen> {
  int? _sliderValue;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(coachSettingsProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coachSettingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen(coachSettingsProvider, (previous, next) {
      if (next case CoachSettingsLoaded(:final settings)) {
        setState(() => _sliderValue = settings.maxClients);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coach Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(state, isDark),
    );
  }

  Widget _buildBody(CoachSettingsState state, bool isDark) {
    return switch (state) {
      CoachSettingsInitial() || CoachSettingsLoading() => const Center(
        child: CircularProgressIndicator(),
      ),
      CoachSettingsError(:final error) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: isDark ? AppColors.error : AppColors.errorLight,
              ),
              const SizedBox(height: 12),
              Text(
                _loadErrorMessage(error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Retry',
                onPressed: () => ref.read(coachSettingsProvider.notifier).load(),
              ),
            ],
          ),
        ),
      ),
      CoachSettingsLoaded(:final settings, :final isUpdating) =>
        _buildSettings(settings, isDark, isUpdating),
    };
  }

  String _loadErrorMessage(AppError error) {
    return errorMessageFor(error);
  }

  Widget _buildSettings(
    CoachSettingsModel settings,
    bool isDark,
    bool isUpdating,
  ) {
    final theme = Theme.of(context);
    final sliderValue = _sliderValue ?? settings.maxClients;
    final atCapacity = settings.activeClientCount >= settings.maxClients;

    return RefreshIndicator(
      onRefresh: () => ref.read(coachSettingsProvider.notifier).load(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          AppCard.elevated(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.settings_outlined,
                      color: isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Client Management',
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Control how clients discover and subscribe to you.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          AppCard.elevated(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Accepting New Clients',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        settings.acceptingClients
                            ? 'New clients can subscribe to you.'
                            : 'New client intake is paused.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isUpdating)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Switch(
                    value: settings.acceptingClients,
                    onChanged: (_) => _toggleAcceptingClients(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          AppCard.elevated(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Public Discovery',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        settings.isDiscoverable
                            ? 'Visible in coach search results.'
                            : 'Hidden from public search — invite-only.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isUpdating)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Switch(
                    value: settings.isDiscoverable,
                    onChanged: (_) => _toggleDiscoverability(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          AppCard.elevated(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Max Clients',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Hard cap on active client count. '
                            'New subscriptions are blocked when full.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.mutedForegroundDark
                                  : AppColors.mutedForegroundLight,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${settings.activeClientCount} / $sliderValue active clients'
                            '${atCapacity ? ' — at capacity' : ''}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: atCapacity
                                  ? (isDark
                                        ? AppColors.warning
                                        : AppColors.warningMuted)
                                  : (isDark
                                        ? AppColors.mutedForegroundDark
                                        : AppColors.mutedForegroundLight),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surface2Dark
                            : AppColors.surface3Light,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Text(
                        '$sliderValue',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.primaryDark
                              : AppColors.primaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppSlider(
                  value: sliderValue.toDouble(),
                  min: 1,
                  max: 200,
                  divisions: 199,
                  disabled: isUpdating,
                  onChanged: (value) {
                    setState(() => _sliderValue = value.round());
                  },
                  onChangeEnd: (value) => _setMaxClients(value.round()),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '1',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                      ),
                      Text(
                        '200',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Quick Actions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton.outline(
                  label: 'Set to 20',
                  onPressed: isUpdating ? null : () => _setMaxClients(20),
                  size: AppButtonSize.sm,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton.outline(
                  label: 'Set to 40',
                  onPressed: isUpdating ? null : () => _setMaxClients(40),
                  size: AppButtonSize.sm,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton.outline(
                  label: 'Set to 100',
                  onPressed: isUpdating ? null : () => _setMaxClients(100),
                  size: AppButtonSize.sm,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAcceptingClients() async {
    final error = await ref
        .read(coachSettingsProvider.notifier)
        .toggleAcceptingClients();
    if (mounted && error != null) {
      AppToast.error(context, errorMessageFor(error));
    }
  }

  Future<void> _toggleDiscoverability() async {
    final error = await ref
        .read(coachSettingsProvider.notifier)
        .toggleDiscoverability();
    if (mounted && error != null) {
      AppToast.error(context, errorMessageFor(error));
    }
  }

  Future<void> _setMaxClients(int value) async {
    final error = await ref
        .read(coachSettingsProvider.notifier)
        .setMaxClients(value);
    if (!mounted) return;

    if (error == null) {
      AppToast.success(context, 'Max clients set to $value');
    } else {
      final message = errorMessageFor(error);
      AppToast.error(context, message);
      if (error.code == ApiErrorCode.coachMaxClientsBelowActive) {
        final current = ref.read(coachSettingsProvider);
        if (current case CoachSettingsLoaded(:final settings)) {
          setState(() => _sliderValue = settings.maxClients);
        }
      }
    }
  }
}
