import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/logger.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/models.dart';
import '../../data/standalone_workout_repository.dart';
import '../providers/standalone_program_provider.dart';

class StandaloneCreateProgramScreen extends ConsumerStatefulWidget {
  const StandaloneCreateProgramScreen({super.key});

  @override
  ConsumerState<StandaloneCreateProgramScreen> createState() =>
      _StandaloneCreateProgramScreenState();
}

class _StandaloneCreateProgramScreenState
    extends ConsumerState<StandaloneCreateProgramScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final repo = ref.read(standaloneWorkoutRepositoryProvider);
    final request = CreateStandaloneProgramRequest(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    final result = await repo.createProgram(request);

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    result.when(
      success: (_) {
        AppLogger.info(
          'Program created successfully',
          tag: 'CreateProgram',
        );
        ref.invalidate(standaloneProgramListProvider);
        context.pop();
      },
      failure: (error) {
        AppLogger.error(
          'Failed to create program',
          tag: 'CreateProgram',
          error: error,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: AppColors.error,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Create Program',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamilySans,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _nameController,
                label: 'Program Name',
                hint: 'e.g. Push Day, Leg Day',
                textCapitalization: TextCapitalization.words,
                autofocus: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a program name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'What does this program focus on?',
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              AppButton.primary(
                label: 'Create Program',
                icon: _isSubmitting ? null : Icons.check,
                onPressed: _isSubmitting ? null : _submit,
                isLoading: _isSubmitting,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
