import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/models.dart';
import '../../data/models/standalone_request_models.dart';
import '../providers/standalone_program_provider.dart';

/// Standalone Program Form Screen
///
/// Create or edit a standalone program (name + description).
class StandaloneProgramFormScreen extends ConsumerStatefulWidget {
  const StandaloneProgramFormScreen({super.key, this.programId});

  /// When non-null the form is in edit mode; otherwise create mode.
  final String? programId;

  @override
  ConsumerState<StandaloneProgramFormScreen> createState() =>
      _StandaloneProgramFormScreenState();
}

class _StandaloneProgramFormScreenState
    extends ConsumerState<StandaloneProgramFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  bool get _isEdit => widget.programId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      Future.microtask(() => _loadExisting());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    final state = ref.read(
      standaloneProgramDetailProvider(widget.programId!),
    );
    if (state is StandaloneProgramDetailLoaded) {
      _populateFields(state.program);
    } else {
      // Load detail for the first time
      await ref
          .read(
            standaloneProgramDetailProvider(widget.programId!).notifier,
          )
          .load();
      final loaded = ref.read(
        standaloneProgramDetailProvider(widget.programId!),
      );
      if (loaded is StandaloneProgramDetailLoaded) {
        _populateFields(loaded.program);
      }
    }
  }

  void _populateFields(StandaloneProgramDetailModel program) {
    _nameController.text = program.name;
    _descriptionController.text = program.description;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Program' : 'New Program'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
              Text(
                _isEdit
                    ? 'Update your program details.'
                    : 'Create a new training program.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
              const SizedBox(height: 24),

              // Name
              AppTextField(
                controller: _nameController,
                label: 'Program Name',
                hint: 'e.g. Push/Pull/Legs',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              AppTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Briefly describe this program',
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              AppButton.primary(
                label: _isEdit ? 'Update Program' : 'Create Program',
                onPressed: _isSubmitting ? null : _submit,
                isLoading: _isSubmitting,
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

    setState(() => _isSubmitting = true);

    try {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();

      bool success;
      if (_isEdit) {
        success = await ref
            .read(
              standaloneProgramDetailProvider(
                widget.programId!,
              ).notifier,
            )
            .updateProgram(
              UpdateStandaloneProgramRequest(
                name: name,
                description: description,
              ),
            );
      } else {
        success = await ref
            .read(standaloneProgramsProvider.notifier)
            .createProgram(
              CreateStandaloneProgramRequest(
                name: name,
                description: description,
              ),
            );
      }

      if (mounted) {
        if (success) {
          AppToast.success(
            context,
            _isEdit ? 'Program updated' : 'Program created',
          );
          context.pop();
        } else {
          AppToast.error(
            context,
            _isEdit ? 'Failed to update program' : 'Failed to create program',
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
