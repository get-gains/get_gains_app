import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:get_gains_app/core/theme/app_colors.dart';
import 'package:get_gains_app/core/utils/app_error.dart';
import 'package:get_gains_app/core/utils/logger.dart';
import 'package:get_gains_app/features/home/presentation/screens/home_screen.dart'
    show isCoachProvider;
import 'package:get_gains_app/providers/router_provider.dart';
import 'package:get_gains_app/widgets/widgets.dart';

import '../providers/coach_invite_provider.dart';

/// Screen for completing coach profile after redeeming an invite code.
class CoachProfileSetupScreen extends ConsumerStatefulWidget {
  const CoachProfileSetupScreen({super.key, required this.invitationCode});

  final String invitationCode;

  @override
  ConsumerState<CoachProfileSetupScreen> createState() =>
      _CoachProfileSetupScreenState();
}

class _CoachProfileSetupScreenState
    extends ConsumerState<CoachProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _certificationsController = TextEditingController();
  final _specialtiesController = TextEditingController();
  final _socialLinksController = TextEditingController();
  final _yearsExperienceController = TextEditingController();
  final _maxClientsController = TextEditingController();
  bool _acceptingClients = true;
  bool _isDiscoverable = true;
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _certificationsController.dispose();
    _specialtiesController.dispose();
    _socialLinksController.dispose();
    _yearsExperienceController.dispose();
    _maxClientsController.dispose();
    super.dispose();
  }

  List<String> _parseCommaList(String value) {
    return value
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final certifications = _parseCommaList(_certificationsController.text);
    final specialties = _parseCommaList(_specialtiesController.text);

    if (certifications.isEmpty || specialties.isEmpty) {
      setState(
        () => _errorText = 'Add at least one certification and specialty',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final yearsExperience = int.tryParse(
      _yearsExperienceController.text.trim(),
    );
    final maxClients = int.tryParse(_maxClientsController.text.trim());

    final repository = ref.read(coachInviteRepositoryProvider);
    final result = await repository.createCoachProfile(
      invitationCode: widget.invitationCode,
      certifications: certifications,
      specialties: specialties,
      socialLinks: _parseCommaList(_socialLinksController.text),
      yearsExperience: yearsExperience,
      maxClients: maxClients,
      acceptingClients: _acceptingClients,
      isDiscoverable: _isDiscoverable,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    result.when(
      success: (_) {
        ref.invalidate(isCoachProvider);
        AppToast.success(context, 'Coach profile created!');
        context.go(AppRoutes.coachHub);
      },
      failure: (error) {
        setState(() => _errorText = _formatError(error));
        AppLogger.warning(
          'Coach profile creation failed: ${error.message}',
          tag: 'CoachProfileSetup',
        );
      },
    );
  }

  String _formatError(AppError error) {
    if (error is ValidationError) return error.message;
    return error.message;
  }

  String? _requiredValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Coach Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set up your coach profile',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Clients will see this information when discovering coaches.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                ),
                const SizedBox(height: 24),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                        controller: _certificationsController,
                        label: 'Certifications',
                        hint: 'e.g. NASM-CPT, ACE, CrossFit L1',
                        helperText: 'Separate with commas',
                        textInputAction: TextInputAction.next,
                        enabled: !_isLoading,
                        validator: (value) =>
                            _requiredValidator(value, 'Certifications'),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _specialtiesController,
                        label: 'Specialties',
                        hint: 'e.g. Strength, Bodybuilding, Mobility',
                        helperText: 'Separate with commas',
                        textInputAction: TextInputAction.next,
                        enabled: !_isLoading,
                        validator: (value) =>
                            _requiredValidator(value, 'Specialties'),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _socialLinksController,
                        label: 'Social / Website Links',
                        hint: 'instagram.com/coach, website.com',
                        helperText: 'Separate with commas (optional)',
                        textInputAction: TextInputAction.next,
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _yearsExperienceController,
                              label: 'Years Experience',
                              hint: '5',
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              enabled: !_isLoading,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppTextField(
                              controller: _maxClientsController,
                              label: 'Max Clients',
                              hint: '20',
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              enabled: !_isLoading,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Accepting new clients'),
                        subtitle: Text(
                          'Let clients request to work with you',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        value: _acceptingClients,
                        onChanged: _isLoading
                            ? null
                            : (value) =>
                                setState(() => _acceptingClients = value),
                      ),
                      Divider(
                        height: 1,
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                      SwitchListTile(
                        title: const Text('Discoverable'),
                        subtitle: Text(
                          'Show up in coach discovery search',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        value: _isDiscoverable,
                        onChanged: _isLoading
                            ? null
                            : (value) =>
                                setState(() => _isDiscoverable = value),
                      ),
                    ],
                  ),
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorMuted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: AppColors.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorText!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                AppButton.primary(
                  label: 'Create Coach Profile',
                  isFullWidth: true,
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
