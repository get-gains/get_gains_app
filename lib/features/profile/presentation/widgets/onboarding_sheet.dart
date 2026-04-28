// lib/features/profile/presentation/widgets/onboarding_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/profile_request_models.dart';
import '../../data/models/user_profile_model.dart';
import '../providers/user_profile_provider.dart';

/// A bottom sheet that walks a first-time user through the minimum
/// profile setup (availability) with optional body metrics.
///
/// Shown on the home screen when [needsOnboardingProvider] is `true`.
///
/// The sheet is **not** dismissible by tapping outside — the user must
/// either complete or skip setup. Skipping uses sensible defaults.
class OnboardingSheet extends ConsumerStatefulWidget {
  const OnboardingSheet({super.key});

  @override
  ConsumerState<OnboardingSheet> createState() => _OnboardingSheetState();
}

class _OnboardingSheetState extends ConsumerState<OnboardingSheet> {
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _injuryController = TextEditingController();

  ExperienceLevel? _experienceLevel;
  Sex? _sex;
  List<String> _equipment = [];
  List<DayOfWeek> _activeWeekdays = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _injuryController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final height = double.tryParse(_heightController.text.trim());
      final weight = double.tryParse(_weightController.text.trim());

      final injury = _injuryController.text.trim();

      final request = CreateUserProfileRequest(
        heightCm: height,
        weightKg: weight,
        experienceLevel: _experienceLevel,
        sex: _sex,
        equipment: _equipment,
        injuryHistory: injury.isEmpty ? null : injury,
        activeWeekdays: _activeWeekdays,
      );

      await ref.read(userProfileProvider.notifier).createProfile(request);

      if (mounted) {
        Navigator.of(context).pop();
        AppToast.success(context, 'Profile set up successfully!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        final message = e is Exception
            ? e.toString().replaceFirst('Exception: ', '')
            : 'Failed to set up profile';
        AppToast.error(context, message);
      }
    }
  }

  void _handleSkip() {
    _handleSave();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Drag handle ─────────────────────────────────────
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Header ──────────────────────────────────────────
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          isDark
                              ? AppColors.primaryDark
                              : AppColors.primaryLight,
                          isDark
                              ? AppColors.primaryDark.withValues(alpha: 0.7)
                              : AppColors.primaryLight.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Welcome to Get Gains!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTextStyles.fontFamilySans,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Let\'s set up your training profile so we can personalise your experience.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    fontFamily: AppTextStyles.fontFamilySans,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // ── Experience level (optional) ─────────────────────
                _SectionLabel(label: 'Experience Level', isDark: isDark),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ExperienceLevel.values.map((level) {
                    final label = switch (level) {
                      ExperienceLevel.beginner => 'Beginner',
                      ExperienceLevel.intermediate => 'Intermediate',
                      ExperienceLevel.advanced => 'Advanced',
                    };
                    return ChoiceChip(
                      label: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: AppTextStyles.fontFamilySans,
                          color: _experienceLevel == level
                              ? Colors.white
                              : null,
                        ),
                      ),
                      selected: _experienceLevel == level,
                      selectedColor: AppColors.primaryDark,
                      onSelected: (_) {
                        setState(() {
                          _experienceLevel = _experienceLevel == level
                              ? null
                              : level;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // ── Active week days ────────────────────────────────
                _SectionLabel(label: 'Active Days', isDark: isDark),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: DayOfWeek.values.map((day) {
                    final isSelected = _activeWeekdays.contains(day);
                    final label = switch (day) {
                      DayOfWeek.sunday => 'Sun',
                      DayOfWeek.monday => 'Mon',
                      DayOfWeek.tuesday => 'Tue',
                      DayOfWeek.wednesday => 'Wed',
                      DayOfWeek.thursday => 'Thu',
                      DayOfWeek.friday => 'Fri',
                      DayOfWeek.saturday => 'Sat',
                    };
                    return FilterChip(
                      label: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: AppTextStyles.fontFamilySans,
                          color: isSelected ? Colors.white : null,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primaryDark,
                      checkmarkColor: Colors.white,
                      onSelected: (_) {
                        setState(() {
                          if (isSelected) {
                            _activeWeekdays.remove(day);
                          } else {
                            _activeWeekdays = [..._activeWeekdays, day];
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // ── Body metrics (optional) ─────────────────────────
                _SectionLabel(
                  label: 'Body Metrics',
                  isDark: isDark,
                  trailing: Text(
                    'Optional',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                      fontFamily: AppTextStyles.fontFamilySans,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _heightController,
                        label: 'Height (cm)',
                        hint: 'e.g. 175',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,1}'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _weightController,
                        label: 'Weight (kg)',
                        hint: 'e.g. 75',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,1}'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Sex selector ────────────────────────────────────
                _SectionLabel(
                  label: 'Sex',
                  isDark: isDark,
                  trailing: Text(
                    'Optional',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                      fontFamily: AppTextStyles.fontFamilySans,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: Text(
                        'Male',
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: AppTextStyles.fontFamilySans,
                          color: _sex == Sex.male ? Colors.white : null,
                        ),
                      ),
                      selected: _sex == Sex.male,
                      selectedColor: AppColors.primaryDark,
                      onSelected: (_) => setState(
                        () => _sex = _sex == Sex.male ? null : Sex.male,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(
                        'Female',
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: AppTextStyles.fontFamilySans,
                          color: _sex == Sex.female ? Colors.white : null,
                        ),
                      ),
                      selected: _sex == Sex.female,
                      selectedColor: AppColors.primaryDark,
                      onSelected: (_) => setState(
                        () => _sex = _sex == Sex.female ? null : Sex.female,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Equipment multi-select ──────────────────────────
                _SectionLabel(
                  label: 'Available Equipment',
                  isDark: isDark,
                  trailing: Text(
                    'Optional',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                      fontFamily: AppTextStyles.fontFamilySans,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableEquipment.map((item) {
                    final isSelected = _equipment.contains(item.toLowerCase());
                    return FilterChip(
                      label: Text(
                        item,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: AppTextStyles.fontFamilySans,
                          color: isSelected ? Colors.white : null,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primaryDark,
                      checkmarkColor: Colors.white,
                      onSelected: (_) {
                        final key = item.toLowerCase();
                        setState(() {
                          if (isSelected) {
                            _equipment.remove(key);
                          } else {
                            _equipment = [..._equipment, key];
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // ── Injury history ──────────────────────────────────
                _SectionLabel(
                  label: 'Injury History',
                  isDark: isDark,
                  trailing: Text(
                    'Optional',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                      fontFamily: AppTextStyles.fontFamilySans,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _injuryController,
                  hint: 'Any injuries or conditions to be aware of...',
                  maxLines: 3,
                  maxLength: 500,
                ),
                const SizedBox(height: 28),

                // ── Actions ─────────────────────────────────────────
                AppButton.primary(
                  label: 'Get Started',
                  onPressed: _isSaving ? null : _handleSave,
                  isLoading: _isSaving,
                  isFullWidth: true,
                  size: AppButtonSize.lg,
                  icon: Icons.arrow_forward_rounded,
                  iconPosition: IconPosition.trailing,
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _isSaving ? null : _handleSkip,
                    child: Text(
                      'Skip for now',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        fontFamily: AppTextStyles.fontFamilySans,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Equipment options ──────────────────────────────────────────────────

const _availableEquipment = [
  'Dumbbells',
  'Barbell',
  'Kettlebells',
  'Resistance Bands',
  'Pull-up Bar',
  'Bench',
  'Cable Machine',
  'Smith Machine',
  'Treadmill',
  'Exercise Bike',
  'Rowing Machine',
  'Foam Roller',
  'Yoga Mat',
  'Medicine Ball',
  'TRX / Suspension',
  'Bodyweight Only',
];

// ─── Section label ──────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.label,
    required this.isDark,
    this.trailing,
  });

  final String label;
  final bool isDark;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark
                ? AppColors.foregroundDark
                : AppColors.foregroundLight,
            fontFamily: AppTextStyles.fontFamilySans,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Shows the onboarding profile setup sheet.
///
/// The sheet is not dismissible — the user must complete or skip setup.
/// Returns after the sheet is closed.
Future<void> showOnboardingSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Theme.of(context).brightness == Brightness.dark
        ? AppColors.surface1Dark
        : AppColors.surface1Light,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const OnboardingSheet(),
  );
}
