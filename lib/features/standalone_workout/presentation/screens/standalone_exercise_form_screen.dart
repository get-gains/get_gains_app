import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../widgets/widgets.dart';
import '../../data/models/models.dart';
import '../../data/models/standalone_request_models.dart';
import '../providers/standalone_exercise_provider.dart';

/// Create / Edit Exercise Form Screen
///
/// When [exerciseId] is null, creates a new personal exercise.
/// When [exerciseId] is provided, edits the existing exercise.
class StandaloneExerciseFormScreen extends ConsumerStatefulWidget {
  const StandaloneExerciseFormScreen({
    super.key,
    this.exerciseId,
    this.exercise,
  });

  final String? exerciseId;
  final StandaloneExerciseModel? exercise;

  bool get isEditing => exerciseId != null;

  @override
  ConsumerState<StandaloneExerciseFormScreen> createState() =>
      _StandaloneExerciseFormScreenState();
}

class _StandaloneExerciseFormScreenState
    extends ConsumerState<StandaloneExerciseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _equipmentController = TextEditingController();
  MuscleGroup _selectedMuscleGroup = MuscleGroup.chest;
  bool _isPublic = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.exercise != null) {
      _nameController.text = widget.exercise!.name;
      _descriptionController.text = widget.exercise!.description;
      _equipmentController.text = widget.exercise!.equipmentNeeded.join(', ');
      _selectedMuscleGroup = widget.exercise!.primaryMuscleGroup;
      _isPublic = widget.exercise!.isPublic;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _equipmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Exercise' : 'Create Exercise'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _nameController,
                label: 'Exercise Name',
                hint: 'e.g. Barbell Bench Press',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Exercise name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Describe the exercise technique...',
                maxLines: 4,
                minLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Muscle group dropdown
              Text(
                'Primary Muscle Group',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<MuscleGroup>(
                value: _selectedMuscleGroup,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: MuscleGroup.values.map((mg) {
                  return DropdownMenuItem(value: mg, child: Text(mg.name));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedMuscleGroup = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _equipmentController,
                label: 'Equipment Needed',
                hint: 'e.g. Barbell, Bench (comma-separated)',
              ),
              const SizedBox(height: 32),

              AppButton.primary(
                label: widget.isEditing ? 'Save Changes' : 'Create Exercise',
                onPressed: _isLoading ? null : _submit,
                isLoading: _isLoading,
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final equipment = _equipmentController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      bool success;

      if (widget.isEditing) {
        success = await ref
            .read(standaloneExercisesProvider.notifier)
            .updateExercise(
              widget.exerciseId!,
              UpdateStandaloneExerciseRequest(
                name: _nameController.text.trim(),
                description: _descriptionController.text.trim(),
                primaryMuscleGroup: _selectedMuscleGroup,
                equipmentNeeded: equipment,
                isPublic: _isPublic,
              ),
            );
      } else {
        success = await ref
            .read(standaloneExercisesProvider.notifier)
            .createExercise(
              CreateStandaloneExerciseRequest(
                name: _nameController.text.trim(),
                description: _descriptionController.text.trim(),
                primaryMuscleGroup: _selectedMuscleGroup,
                equipmentNeeded: equipment,
                isPublic: _isPublic,
              ),
            );
      }

      if (mounted) {
        if (success) {
          AppToast.success(
            context,
            widget.isEditing ? 'Exercise updated' : 'Exercise created',
          );
          context.pop();
        } else {
          AppToast.error(
            context,
            widget.isEditing
                ? 'Failed to update exercise'
                : 'Failed to create exercise',
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
