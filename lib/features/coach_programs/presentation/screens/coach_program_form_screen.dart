import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../widgets/widgets.dart';
import '../../data/models/program_request_models.dart';
import '../providers/coach_program_provider.dart';

/// Create / Edit Program Form Screen
///
/// When [programId] is null, creates a new program.
/// When [programId] is provided, loads and edits the existing program.
class CoachProgramFormScreen extends ConsumerStatefulWidget {
  const CoachProgramFormScreen({super.key, this.programId});

  final String? programId;

  bool get isEditing => programId != null;

  @override
  ConsumerState<CoachProgramFormScreen> createState() =>
      _CoachProgramFormScreenState();
}

class _CoachProgramFormScreenState
    extends ConsumerState<CoachProgramFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
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
    // Load from the detail provider if editing
    final notifier = ref.read(
      programDetailProvider(widget.programId!).notifier,
    );
    await notifier.load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Pre-fill form when editing and data is loaded
    if (widget.isEditing && !_hasLoadedExisting) {
      final detailState = ref.watch(programDetailProvider(widget.programId!));
      if (detailState is ProgramDetailLoaded) {
        _nameController.text = detailState.program.name;
        _descriptionController.text = detailState.program.description;
        _hasLoadedExisting = true;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Program' : 'Create Program'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildForm(isDark),
    );
  }

  Widget _buildForm(bool isDark) {
    // Show loading while fetching existing program data
    if (widget.isEditing && !_hasLoadedExisting) {
      final detailState = ref.watch(programDetailProvider(widget.programId!));
      if (detailState is ProgramDetailLoading ||
          detailState is ProgramDetailInitial) {
        return const Center(child: CircularProgressIndicator());
      }
      if (detailState is ProgramDetailError) {
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
              label: 'Program Name',
              hint: 'e.g. Push Pull Legs',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Program name is required';
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
              hint: 'Describe what this program focuses on...',
              maxLines: 4,
              minLines: 3,
            ),
            const SizedBox(height: 32),
            AppButton.primary(
              label: widget.isEditing ? 'Save Changes' : 'Create Program',
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

      if (widget.isEditing) {
        success = await ref
            .read(coachProgramsProvider.notifier)
            .updateProgram(
              widget.programId!,
              UpdateProgramRequest(
                name: _nameController.text.trim(),
                description: _descriptionController.text.trim(),
              ),
            );
      } else {
        success = await ref
            .read(coachProgramsProvider.notifier)
            .createProgram(
              CreateProgramRequest(
                name: _nameController.text.trim(),
                description: _descriptionController.text.trim(),
              ),
            );
      }

      if (mounted) {
        if (success) {
          AppToast.success(
            context,
            widget.isEditing ? 'Program updated' : 'Program created',
          );
          context.pop();
        } else {
          AppToast.error(
            context,
            widget.isEditing
                ? 'Failed to update program'
                : 'Failed to create program',
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
