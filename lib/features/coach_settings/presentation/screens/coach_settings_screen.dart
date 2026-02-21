import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
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
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(coachSettingsProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coachSettingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: isDark ? AppColors.error : AppColors.errorLight,
            ),
            const SizedBox(height: 12),
            Text(error.message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            AppButton(
              label: 'Retry',
              onPressed: () => ref.read(coachSettingsProvider.notifier).load(),
            ),
          ],
        ),
      ),
      CoachSettingsLoaded(:final settings) => _buildSettings(settings, isDark),
    };
  }

  Widget _buildSettings(CoachSettingsModel settings, bool isDark) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () => ref.read(coachSettingsProvider.notifier).load(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // ── Header Card ──────────────────────────────
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

          // ── Accepting Clients Toggle ─────────────────
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
                Switch(
                  value: settings.acceptingClients,
                  onChanged: (_) => _toggleAcceptingClients(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Discoverable Toggle ──────────────────────
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
                Switch(
                  value: settings.isDiscoverable,
                  onChanged: (_) => _toggleDiscoverability(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Max Clients ──────────────────────────────
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
                        '${settings.maxClients}',
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
                  value: settings.maxClients.toDouble(),
                  min: 1,
                  max: 200,
                  divisions: 199,
                  onChanged: (value) {
                    // Update local display only during drag
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

          // ── Quick Actions ────────────────────────────
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
                  onPressed: () => _setMaxClients(20),
                  size: AppButtonSize.sm,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton.outline(
                  label: 'Set to 40',
                  onPressed: () => _setMaxClients(40),
                  size: AppButtonSize.sm,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton.outline(
                  label: 'Set to 100',
                  onPressed: () => _setMaxClients(100),
                  size: AppButtonSize.sm,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // Actions
  // ──────────────────────────────────────────────────────────

  Future<void> _toggleAcceptingClients() async {
    final success = await ref
        .read(coachSettingsProvider.notifier)
        .toggleAcceptingClients();
    if (mounted && !success) {
      AppToast.error(context, 'Failed to update setting');
    }
  }

  Future<void> _toggleDiscoverability() async {
    final success = await ref
        .read(coachSettingsProvider.notifier)
        .toggleDiscoverability();
    if (mounted && !success) {
      AppToast.error(context, 'Failed to update setting');
    }
  }

  Future<void> _setMaxClients(int value) async {
    final success = await ref
        .read(coachSettingsProvider.notifier)
        .setMaxClients(value);
    if (mounted) {
      if (success) {
        AppToast.success(context, 'Max clients set to $value');
      } else {
        AppToast.error(context, 'Failed to update max clients');
      }
    }
  }
}
