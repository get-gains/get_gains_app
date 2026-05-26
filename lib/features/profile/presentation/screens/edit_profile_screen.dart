// lib/features/profile/presentation/screens/edit_profile_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/user_profile_model.dart';
import '../providers/edit_profile_provider.dart';
import '../providers/profile_provider.dart';

/// Screen for editing the user's fitness profile.
///
/// All fields are pre-populated from the current [UserProfileModel].
/// Avatar changes use [ImagePicker] and are uploaded as multipart
/// form-data when the user taps **Save**.
///
/// This screen is **online-only** – the router / profile screen gates
/// access via `canEditProfileProvider`.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late final TextEditingController _bioController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _injuryController;

  @override
  void initState() {
    super.initState();
    final form = ref.read(editProfileProvider);
    _bioController = TextEditingController(text: form.bio ?? '');
    _heightController = TextEditingController(
      text: form.heightCm != null ? form.heightCm!.toStringAsFixed(1) : '',
    );
    _weightController = TextEditingController(
      text: form.weightKg != null ? form.weightKg!.toStringAsFixed(1) : '',
    );
    _injuryController = TextEditingController(text: form.injuryHistory ?? '');
  }

  @override
  void dispose() {
    _bioController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _injuryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    // Request appropriate permission before picking
    final hasPermission = await _requestPermission(source);
    if (!hasPermission) return;

    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null) {
        ref.read(editProfileProvider.notifier).pickAvatar(picked.path);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to pick image');
      }
    }
  }

  /// Requests the appropriate runtime permission for [source].
  ///
  /// Returns `true` if the permission is granted (or was already granted).
  /// Shows a settings prompt when the user has permanently denied access.
  Future<bool> _requestPermission(ImageSource source) async {
    late final Permission permission;

    if (source == ImageSource.camera) {
      permission = Permission.camera;
    } else {
      // On Android 13+ use photos; older versions use storage
      permission = Platform.isAndroid ? Permission.photos : Permission.photos;
    }

    var status = await permission.status;

    // Already granted
    if (status.isGranted || status.isLimited) return true;

    // Request permission
    status = await permission.request();

    if (status.isGranted || status.isLimited) return true;

    // Permanently denied → offer to open settings
    if (status.isPermanentlyDenied && mounted) {
      final label = source == ImageSource.camera ? 'camera' : 'photo library';
      final shouldOpen = await showAppConfirmDialog(
        context: context,
        title: 'Permission Required',
        message:
            'Get Gains needs access to your $label to set a profile photo. '
            'Please enable it in Settings.',
        confirmLabel: 'Open Settings',
        cancelLabel: 'Cancel',
      );
      if (shouldOpen == true) {
        await openAppSettings();
      }
      return false;
    }

    // Denied (not permanent) – just inform the user
    if (mounted) {
      final label = source == ImageSource.camera ? 'Camera' : 'Photo library';
      AppToast.warning(context, '$label permission is required');
    }
    return false;
  }

  void _showAvatarOptions() {
    final form = ref.read(editProfileProvider);
    final hasAvatar =
        form.avatarFilePath != null ||
        (form.existingAvatarUrl != null && !form.removeAvatar);

    final actions = <AppActionSheetItem<String>>[
      const AppActionSheetItem(
        label: 'Take Photo',
        value: 'camera',
        icon: Icons.camera_alt_outlined,
      ),
      const AppActionSheetItem(
        label: 'Choose from Gallery',
        value: 'gallery',
        icon: Icons.photo_library_outlined,
      ),
      if (hasAvatar)
        const AppActionSheetItem(
          label: 'Remove Photo',
          value: 'remove',
          icon: Icons.delete_outline,
          isDestructive: true,
        ),
    ];

    showAppActionSheet<String>(
      context: context,
      title: 'Profile Photo',
      actions: actions,
    ).then((value) {
      if (value == null) return;
      switch (value) {
        case 'camera':
          _pickImage(ImageSource.camera);
        case 'gallery':
          _pickImage(ImageSource.gallery);
        case 'remove':
          ref.read(editProfileProvider.notifier).removeCurrentAvatar();
      }
    });
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Sync text controller values into the notifier
    final notifier = ref.read(editProfileProvider.notifier);
    final bio = _bioController.text.trim();
    final height = double.tryParse(_heightController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());
    final injury = _injuryController.text.trim();

    notifier.updateBio(bio.isEmpty ? null : bio);
    notifier.updateHeightCm(height);
    notifier.updateWeightKg(weight);
    notifier.updateInjuryHistory(injury.isEmpty ? null : injury);

    final success = await notifier.save();
    if (success && mounted) {
      AppToast.success(context, 'Profile updated');
      context.pop();
    } else if (!success && mounted) {
      final errorMsg = ref.read(editProfileProvider).errorMessage;
      AppToast.error(context, errorMsg ?? 'Failed to save profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(editProfileProvider);
    final profileAsync = ref.watch(profileProvider);
    final userName = profileAsync.asData?.value.name;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App bar ──────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => context.pop(),
              ),
              title: Text(
                'Edit Profile',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AppButton(
                    label: 'Save',
                    onPressed: form.isSaving ? null : _handleSave,
                    isLoading: form.isSaving,
                    size: AppButtonSize.sm,
                  ),
                ),
              ],
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),

            // ── Form body ────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),

                        // ── Avatar picker ────────────────────────────
                        _AvatarPicker(
                          existingUrl: form.existingAvatarUrl,
                          pickedFilePath: form.avatarFilePath,
                          isRemoved: form.removeAvatar,
                          onTap: _showAvatarOptions,
                          isDark: isDark,
                          name: userName,
                        ),
                        const SizedBox(height: 32),

                        // ── Bio ──────────────────────────────────────
                        _SectionLabel(label: 'About', isDark: isDark),
                        const SizedBox(height: 8),
                        AppTextField(
                          controller: _bioController,
                          hint: 'Tell us about yourself...',
                          maxLines: 3,
                          maxLength: 500,
                        ),
                        const SizedBox(height: 24),

                        // ── Body metrics ─────────────────────────────
                        _SectionLabel(label: 'Body Metrics', isDark: isDark),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _heightController,
                                label: 'Height (cm)',
                                hint: 'e.g. 175.0',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
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
                                hint: 'e.g. 75.0',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
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
                        const SizedBox(height: 16),
                        _SexSelector(
                          value: form.sex,
                          isDark: isDark,
                          onChanged: (v) => ref
                              .read(editProfileProvider.notifier)
                              .updateSex(v),
                        ),
                        const SizedBox(height: 16),
                        _DateOfBirthField(
                          value: form.dateOfBirth,
                          isDark: isDark,
                          onChanged: (v) => ref
                              .read(editProfileProvider.notifier)
                              .updateDateOfBirth(v),
                        ),
                        const SizedBox(height: 24),

                        // ── Training preferences ─────────────────────
                        _SectionLabel(
                          label: 'Training Preferences',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 8),
                        _ExperienceLevelSelector(
                          value: form.experienceLevel,
                          isDark: isDark,
                          onChanged: (v) => ref
                              .read(editProfileProvider.notifier)
                              .updateExperienceLevel(v),
                        ),
                        const SizedBox(height: 16),
                        _EquipmentSelector(
                          selected: form.equipment,
                          isDark: isDark,
                          onChanged: (v) => ref
                              .read(editProfileProvider.notifier)
                              .updateEquipment(v),
                        ),
                        const SizedBox(height: 24),

                        // ── Injury history ───────────────────────────
                        _SectionLabel(label: 'Injury History', isDark: isDark),
                        const SizedBox(height: 8),
                        AppTextField(
                          controller: _injuryController,
                          hint: 'Any injuries or conditions to be aware of...',
                          maxLines: 3,
                          maxLength: 500,
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Avatar Picker ──────────────────────────────────────────────────────

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.existingUrl,
    required this.pickedFilePath,
    required this.isRemoved,
    required this.onTap,
    required this.isDark,
    this.name,
  });

  final String? existingUrl;
  final String? pickedFilePath;
  final bool isRemoved;
  final VoidCallback onTap;
  final bool isDark;
  final String? name;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            _buildAvatar(context),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? AppColors.backgroundDark
                        : AppColors.backgroundLight,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    // Show picked local file
    if (pickedFilePath != null) {
      return CircleAvatar(
        radius: 48,
        backgroundImage: FileImage(File(pickedFilePath!)),
      );
    }

    // Show existing server avatar (not removed)
    if (existingUrl != null && !isRemoved) {
      return AppAvatar(imageUrl: existingUrl, name: name, size: AppAvatarSize.xxl);
    }

    // No avatar – show placeholder with camera icon
    return AppAvatar.icon(
      icon: Icons.person_add_alt_1,
      size: AppAvatarSize.xxl,
    );
  }
}

// ─── Section label ──────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.isDark});

  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.foregroundDark : AppColors.foregroundLight,
        fontFamily: AppTextStyles.fontFamilySans,
      ),
    );
  }
}

// ─── Sex selector ───────────────────────────────────────────────────────

class _SexSelector extends StatelessWidget {
  const _SexSelector({
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  final Sex? value;
  final bool isDark;
  final ValueChanged<Sex?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sex',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
            fontFamily: AppTextStyles.fontFamilySans,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _ChoiceChipItem(
              label: 'Male',
              selected: value == Sex.male,
              onSelected: () => onChanged(value == Sex.male ? null : Sex.male),
            ),
            const SizedBox(width: 8),
            _ChoiceChipItem(
              label: 'Female',
              selected: value == Sex.female,
              onSelected: () =>
                  onChanged(value == Sex.female ? null : Sex.female),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Experience level selector ──────────────────────────────────────────

class _ExperienceLevelSelector extends StatelessWidget {
  const _ExperienceLevelSelector({
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  final ExperienceLevel? value;
  final bool isDark;
  final ValueChanged<ExperienceLevel?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Experience Level',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
            fontFamily: AppTextStyles.fontFamilySans,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ExperienceLevel.values.map((level) {
            final label = switch (level) {
              ExperienceLevel.beginner => 'Beginner',
              ExperienceLevel.intermediate => 'Intermediate',
              ExperienceLevel.advanced => 'Advanced',
            };
            return _ChoiceChipItem(
              label: label,
              selected: value == level,
              onSelected: () => onChanged(value == level ? null : level),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Equipment multi-select ─────────────────────────────────────────────

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

class _EquipmentSelector extends StatelessWidget {
  const _EquipmentSelector({
    required this.selected,
    required this.isDark,
    required this.onChanged,
  });

  final List<String> selected;
  final bool isDark;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Equipment',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
            fontFamily: AppTextStyles.fontFamilySans,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableEquipment.map((item) {
            final isSelected = selected.contains(item.toLowerCase());
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
                final updated = List<String>.from(selected);
                if (isSelected) {
                  updated.remove(key);
                } else {
                  updated.add(key);
                }
                onChanged(updated);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Date of birth field ────────────────────────────────────────────────

class _DateOfBirthField extends StatelessWidget {
  const _DateOfBirthField({
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  final DateTime? value;
  final bool isDark;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final display = value != null
        ? '${value!.day}/${value!.month}/${value!.year}'
        : 'Not set';

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime(1995, 1, 1),
          firstDate: DateTime(1920),
          lastDate: DateTime.now(),
          helpText: 'Date of Birth',
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date of Birth',
          hintText: 'Tap to select',
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (value != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => onChanged(null),
                ),
              const Icon(Icons.calendar_today_outlined, size: 18),
              const SizedBox(width: 12),
            ],
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          display,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: value == null
                ? (isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight)
                : null,
            fontFamily: AppTextStyles.fontFamilySans,
          ),
        ),
      ),
    );
  }
}

// ─── Reusable choice chip ───────────────────────────────────────────────

class _ChoiceChipItem extends StatelessWidget {
  const _ChoiceChipItem({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontFamily: AppTextStyles.fontFamilySans,
          color: selected ? Colors.white : null,
        ),
      ),
      selected: selected,
      selectedColor: AppColors.primaryDark,
      onSelected: (_) => onSelected(),
    );
  }
}
