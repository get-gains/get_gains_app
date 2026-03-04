import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../widgets/widgets.dart';
import '../../data/models/models.dart';
import '../../data/models/standalone_request_models.dart';
import '../providers/standalone_routine_provider.dart';

/// Create / Edit Routine Form Screen
///
/// When [routineId] is null, creates a new routine.
/// When [routineId] is provided, edits the existing routine.
class StandaloneRoutineFormScreen extends ConsumerStatefulWidget {
  const StandaloneRoutineFormScreen({super.key, this.routineId});

  final String? routineId;

  bool get isEditing => routineId != null;

  @override
  ConsumerState<StandaloneRoutineFormScreen> createState() =>
      _StandaloneRoutineFormScreenState();
}

class _StandaloneRoutineFormScreenState
    extends ConsumerState<StandaloneRoutineFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController(text: '45');
  List<MuscleGroup> _selectedMuscleGroups = [];
  bool _isLoading = false;
  bool _hasLoadedExisting = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    final notifier = ref.read(
      standaloneRoutineDetailProvider(widget.routineId!).notifier,
    );
    await notifier.load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pre-fill form when editing
    if (widget.isEditing && !_hasLoadedExisting) {
      final detailState = ref.watch(
        standaloneRoutineDetailProvider(widget.routineId!),
      );
      if (detailState is StandaloneRoutineDetailLoaded) {
        _nameController.text = detailState.routine.name;
        _descriptionController.text = detailState.routine.description;
        _durationController.text = detailState.routine.estimatedDurationMinutes
            .toString();
        _selectedMuscleGroups = List.of(
          detailState.routine.muscleGroupsTargeted,
        );
        _hasLoadedExisting = true;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Routine' : 'Create Routine'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildForm(),
    );
  }

  Widget _buildForm() {
    // Show loading while fetching existing data
    if (widget.isEditing && !_hasLoadedExisting) {
      final detailState = ref.watch(
        standaloneRoutineDetailProvider(widget.routineId!),
      );
      if (detailState is StandaloneRoutineDetailLoading ||
          detailState is StandaloneRoutineDetailInitial) {
        return const Center(child: CircularProgressIndicator());
      }
      if (detailState is StandaloneRoutineDetailError) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(detailState.error.message),
              const SizedBox(height: 16),
              AppButton(label: 'Retry', onPressed: _loadExisting),
            ],
          ),
        );
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _nameController,
              label: 'Routine Name',
              hint: 'e.g. Upper Body Push',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Routine name is required';
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
              hint: 'Describe the routine focus...',
              maxLines: 3,
              minLines: 2,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _durationController,
              label: 'Estimated Duration (minutes)',
              hint: '45',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Duration is required';
                }
                final mins = int.tryParse(value.trim());
                if (mins == null || mins < 1) {
                  return 'Enter a valid number of minutes';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Muscle groups picker
            Text(
              'Muscle Groups Targeted',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MuscleGroup.values.map((mg) {
                final isSelected = _selectedMuscleGroups.contains(mg);
                return FilterChip(
                  label: Text(mg.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedMuscleGroups.add(mg);
                      } else {
                        _selectedMuscleGroups.remove(mg);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 32),
            AppButton.primary(
              label: widget.isEditing ? 'Save Changes' : 'Create Routine',
              onPressed: _isLoading ? null : _submit,
              isLoading: _isLoading,
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      bool success;
      final duration = int.parse(_durationController.text.trim());

      if (widget.isEditing) {
        success = await ref
            .read(
              standaloneRoutineDetailProvider(
                widget.routineId!,
              ).notifier,
            )
            .updateRoutine(
              UpdateStandaloneRoutineRequest(
                name: _nameController.text.trim(),
                description: _descriptionController.text.trim(),
                estimatedDurationMinutes: duration,
                muscleGroupsTargeted: _selectedMuscleGroups,
              ),
            );
      } else {
        success = await ref
            .read(standaloneRoutinesProvider.notifier)
            .createRoutine(
              CreateStandaloneRoutineRequest(
                name: _nameController.text.trim(),
                description: _descriptionController.text.trim(),
                estimatedDurationMinutes: duration,
                muscleGroupsTargeted: _selectedMuscleGroups,
              ),
            );
      }

      if (mounted) {
        if (success) {
          AppToast.success(
            context,
            widget.isEditing ? 'Routine updated' : 'Routine created',
          );
          context.pop();
        } else {
          AppToast.error(
            context,
            widget.isEditing
                ? 'Failed to update routine'
                : 'Failed to create routine',
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
