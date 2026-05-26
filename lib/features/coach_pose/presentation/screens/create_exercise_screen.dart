import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../workout/data/models/exercise_model.dart';
import '../providers/create_exercise_provider.dart';
import '../providers/exercise_list_provider.dart';

/// Screen for creating a new exercise.
///
/// Form includes: name, description, primary muscle group, equipment.
class CreateExerciseScreen extends ConsumerStatefulWidget {
  const CreateExerciseScreen({super.key});

  @override
  ConsumerState<CreateExerciseScreen> createState() =>
      _CreateExerciseScreenState();
}

class _CreateExerciseScreenState extends ConsumerState<CreateExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _equipmentController = TextEditingController();
  MuscleGroup _selectedMuscleGroup = MuscleGroup.chest;
  final List<String> _equipment = [];
  bool _isPublic = true;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _equipmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createExerciseProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen for state changes
    ref.listen<CreateExerciseState>(createExerciseProvider, (previous, next) {
      if (next is CreateExerciseSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exercise "${next.exercise.name}" created!'),
            backgroundColor: isDark
                ? AppColors.successMuted
                : AppColors.successLight,
          ),
        );
        // Refresh the exercise list
        ref.read(exerciseListProvider.notifier).refresh();
        context.pop();
      } else if (next is CreateExerciseError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: isDark ? AppColors.error : AppColors.errorLight,
          ),
        );
      }
    });

    final isLoading = state is CreateExerciseLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Exercise'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Exercise Name',
                hintText: 'e.g., Barbell Back Squat',
                filled: true,
                fillColor: isDark
                    ? AppColors.surface1Dark
                    : AppColors.inputLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Exercise name is required';
                }
                if (value.trim().length < 3) {
                  return 'Name must be at least 3 characters';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Brief description of the exercise...',
                filled: true,
                fillColor: isDark
                    ? AppColors.surface1Dark
                    : AppColors.inputLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Description is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Primary Muscle Group dropdown
            Text(
              'Primary Muscle Group',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surface1Dark : AppColors.inputLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<MuscleGroup>(
                  value: _selectedMuscleGroup,
                  isExpanded: true,
                  dropdownColor: isDark
                      ? AppColors.surface2Dark
                      : AppColors.cardLight,
                  items: MuscleGroup.values.map((group) {
                    return DropdownMenuItem(
                      value: group,
                      child: Text(group.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedMuscleGroup = value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Equipment
            Text(
              'Equipment Needed',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _equipmentController,
                    decoration: InputDecoration(
                      hintText: 'e.g., Barbell',
                      filled: true,
                      fillColor: isDark
                          ? AppColors.surface1Dark
                          : AppColors.inputLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _addEquipment(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addEquipment,
                  icon: Icon(
                    Icons.add_circle,
                    color: isDark
                        ? AppColors.primaryDark
                        : AppColors.primaryLight,
                  ),
                ),
              ],
            ),
            if (_equipment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _equipment.map((e) {
                  return Chip(
                    label: Text(e),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() => _equipment.remove(e));
                    },
                    backgroundColor: isDark
                        ? AppColors.surface2Dark
                        : AppColors.secondaryLight,
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 24),

            // Public / Private toggle
            _buildVisibilityToggle(isDark),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : _onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? AppColors.primaryDark
                      : AppColors.primaryLight,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Create Exercise',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilityToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface1Dark : AppColors.inputLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            _isPublic ? Icons.public : Icons.lock,
            color: _isPublic
                ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                : (isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isPublic ? 'Public Exercise' : 'Private Exercise',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _isPublic
                      ? 'Visible in the Form Library for all users'
                      : 'Only visible to you',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isPublic,
            activeTrackColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            onChanged: (value) => setState(() => _isPublic = value),
          ),
        ],
      ),
    );
  }

  void _addEquipment() {
    final text = _equipmentController.text.trim();
    if (text.isNotEmpty && !_equipment.contains(text)) {
      setState(() {
        _equipment.add(text);
        _equipmentController.clear();
      });
    }
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    ref
        .read(createExerciseProvider.notifier)
        .createExercise(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          primaryMuscleGroup: _selectedMuscleGroup,
          equipmentNeeded: _equipment,
          isPublic: _isPublic,
        );
  }
}
