import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static const int _minMaxClients = 1;
  static const int _maxMaxClients = 200;

  int? _sliderValue;
  late final TextEditingController _maxClientsController;
  late final FocusNode _maxClientsFocusNode;

  @override
  void initState() {
    super.initState();
    _maxClientsController = TextEditingController();
    _maxClientsFocusNode = FocusNode();
    _maxClientsFocusNode.addListener(_handleMaxClientsFocusChange);
    Future.microtask(() => ref.read(coachSettingsProvider.notifier).load());
  }

  @override
  void dispose() {
    _maxClientsFocusNode.removeListener(_handleMaxClientsFocusChange);
    _maxClientsFocusNode.dispose();
    _maxClientsController.dispose();
    super.dispose();
  }

  void _handleMaxClientsFocusChange() {
    if (!_maxClientsFocusNode.hasFocus) {
      final current = ref.read(coachSettingsProvider);
      if (current case CoachSettingsLoaded(:final settings)) {
        _commitMaxClientsInput(settings.maxClients);
      }
    }
  }

  int _clampMaxClients(int value) =>
      value.clamp(_minMaxClients, _maxMaxClients);

  void _syncMaxClientsDisplay(int value) {
    if (_maxClientsFocusNode.hasFocus) return;
    final text = value.toString();
    if (_maxClientsController.text != text) {
      _maxClientsController.text = text;
    }
  }

  void _commitMaxClientsInput(int fallback) {
    final parsed = int.tryParse(_maxClientsController.text.trim());
    if (parsed == null) {
      _syncMaxClientsDisplay(fallback);
      setState(() => _sliderValue = fallback);
      return;
    }

    final clamped = _clampMaxClients(parsed);
    _syncMaxClientsDisplay(clamped);
    setState(() => _sliderValue = clamped);

    final current = ref.read(coachSettingsProvider);
    if (current case CoachSettingsLoaded(:final settings)) {
      if (clamped != settings.maxClients) {
        _setMaxClients(clamped);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coachSettingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen(coachSettingsProvider, (previous, next) {
      if (next case CoachSettingsLoaded(:final settings)) {
        setState(() {
          _sliderValue = settings.maxClients;
          _syncMaxClientsDisplay(settings.maxClients);
        });
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
      CoachSettingsLoaded(:final settings, :final updatingField) =>
        _buildSettings(settings, isDark, updatingField),
    };
  }

  String _loadErrorMessage(AppError error) {
    return errorMessageFor(error);
  }

  Widget _buildSettings(
    CoachSettingsModel settings,
    bool isDark,
    CoachSettingsUpdateField? updatingField,
  ) {
    final theme = Theme.of(context);
    final sliderValue = _sliderValue ?? settings.maxClients;
    final atCapacity = settings.activeClientCount >= settings.maxClients;
    final isUpdatingAccepting =
        updatingField == CoachSettingsUpdateField.acceptingClients;
    final isUpdatingDiscoverable =
        updatingField == CoachSettingsUpdateField.isDiscoverable;
    final isUpdatingMaxClients =
        updatingField == CoachSettingsUpdateField.maxClients;

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
                _buildSettingsSwitch(
                  value: settings.acceptingClients,
                  isUpdating: isUpdatingAccepting,
                  isDark: isDark,
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
                _buildSettingsSwitch(
                  value: settings.isDiscoverable,
                  isUpdating: isUpdatingDiscoverable,
                  isDark: isDark,
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
                            'New subscriptions are blocked when full. '
                            'Drag the slider or tap the number to set a limit.',
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tap to edit',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isDark
                                ? AppColors.primaryDark
                                : AppColors.primaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isUpdatingMaxClients
                                ? null
                                : () => _maxClientsFocusNode.requestFocus(),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                            child: SizedBox(
                              width: 104,
                              child: AppTextField(
                                controller: _maxClientsController,
                                focusNode: _maxClientsFocusNode,
                                variant: AppTextFieldVariant.outlined,
                                size: AppTextFieldSize.sm,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                enabled: !isUpdatingMaxClients,
                                suffixIcon: Icons.edit_outlined,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (value) {
                                  final parsed = int.tryParse(value);
                                  if (parsed != null) {
                                    setState(
                                      () =>
                                          _sliderValue = _clampMaxClients(parsed),
                                    );
                                  }
                                },
                                onSubmitted: (_) => _commitMaxClientsInput(
                                  settings.maxClients,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppSlider(
                  value: sliderValue.toDouble(),
                  min: _minMaxClients.toDouble(),
                  max: _maxMaxClients.toDouble(),
                  divisions: _maxMaxClients - _minMaxClients,
                  disabled: isUpdatingMaxClients,
                  onChanged: (value) {
                    final rounded = value.round();
                    setState(() => _sliderValue = rounded);
                    _syncMaxClientsDisplay(rounded);
                  },
                  onChangeEnd: (value) => _setMaxClients(value.round()),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$_minMaxClients',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                      ),
                      Text(
                        '$_maxMaxClients',
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
        ],
      ),
    );
  }

  Widget _buildSettingsSwitch({
    required bool value,
    required bool isUpdating,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isUpdating) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            ),
          ),
          const SizedBox(width: 10),
        ],
        Switch(
          value: value,
          onChanged: isUpdating ? null : onChanged,
        ),
      ],
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
    final clamped = _clampMaxClients(value);
    setState(() => _sliderValue = clamped);
    _syncMaxClientsDisplay(clamped);

    final error = await ref
        .read(coachSettingsProvider.notifier)
        .setMaxClients(clamped);
    if (!mounted) return;

    if (error == null) {
      AppToast.success(context, 'Max clients set to $clamped');
    } else {
      final message = errorMessageFor(error);
      AppToast.error(context, message);
      if (error.code == ApiErrorCode.coachMaxClientsBelowActive) {
        final current = ref.read(coachSettingsProvider);
        if (current case CoachSettingsLoaded(:final settings)) {
          setState(() => _sliderValue = settings.maxClients);
          _syncMaxClientsDisplay(settings.maxClients);
        }
      }
    }
  }
}
