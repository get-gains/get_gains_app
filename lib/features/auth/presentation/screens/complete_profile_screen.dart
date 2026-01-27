// lib/features/auth/presentation/screens/complete_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../providers/register_provider.dart';

/// Complete Profile Screen
///
/// Second step of Google sign-up flow.
/// User enters name and nickname after Google OAuth.
class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();

  final _nameFocus = FocusNode();
  final _nicknameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _animationController.forward();

    // Pre-fill suggested name from Google account
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(registerProvider);
      if (state is RegisterGooglePendingProfile &&
          state.suggestedName != null) {
        _nameController.text = state.suggestedName!;
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _nicknameController.dispose();
    _nameFocus.dispose();
    _nicknameFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final registerState = ref.watch(registerProvider);

    // Listen for state changes
    ref.listen<RegisterState>(registerProvider, (previous, next) {
      if (next is RegisterSuccess) {
        context.go(AppRoutes.home);
      } else if (next is RegisterError) {
        _showErrorSnackbar(next.error.message);
      }
    });

    final isLoading = registerState is RegisterLoading;
    final pendingProfile = registerState is RegisterGooglePendingProfile
        ? registerState
        : null;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),

                    // Header with Icon
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildHeader(isDark, pendingProfile?.email),
                    ),

                    const SizedBox(height: 48),

                    // Form
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildForm(isDark, isLoading),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Submit Button
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildSubmitButton(isDark, isLoading),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Cancel Link
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildCancelLink(isDark, isLoading),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, String? email) {
    return Column(
      children: [
        // Success Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppColors.successGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withOpacity(0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.check_rounded, size: 40, color: Colors.white),
        ),

        const SizedBox(height: 24),

        // Title
        Text(
          'Almost There!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.foregroundDark
                : AppColors.foregroundLight,
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 8),

        // Subtitle
        Text(
          'Complete your profile to get started',
          style: TextStyle(
            fontSize: 16,
            color: isDark
                ? AppColors.mutedForegroundDark
                : AppColors.mutedForegroundLight,
          ),
        ),

        if (email != null) ...[
          const SizedBox(height: 16),
          // Email Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface1Dark : AppColors.surface1Light,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              border: Border.all(
                color: isDark
                    ? AppColors.borderDark.withOpacity(0.5)
                    : AppColors.borderLight,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.email_outlined,
                  size: 16,
                  color: isDark
                      ? AppColors.primaryDark
                      : AppColors.primaryLight,
                ),
                const SizedBox(width: 8),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.foregroundDark
                        : AppColors.foregroundLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildForm(bool isDark, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Name Field
        AppTextField(
          controller: _nameController,
          focusNode: _nameFocus,
          label: 'Full Name',
          hint: 'Enter your full name',
          prefixIcon: Icons.person_outline_rounded,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          enabled: !isLoading,
          validator: _validateName,
          onSubmitted: (_) => _nicknameFocus.requestFocus(),
        ),

        const SizedBox(height: 20),

        // Nickname Field
        AppTextField(
          controller: _nicknameController,
          focusNode: _nicknameFocus,
          label: 'Nickname',
          hint: 'Choose a unique nickname',
          helperText: 'This will be visible to other users',
          prefixIcon: Icons.alternate_email_rounded,
          textInputAction: TextInputAction.done,
          enabled: !isLoading,
          validator: _validateNickname,
          onSubmitted: (_) => _handleSubmit(),
        ),

        const SizedBox(height: 16),

        // Info Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppColors.info.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 20, color: AppColors.info),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your nickname must be unique and will be used to identify you in the app.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.foregroundDark.withOpacity(0.8)
                        : AppColors.foregroundLight.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool isDark, bool isLoading) {
    return AppButton.primary(
      label: 'Complete Setup',
      onPressed: isLoading ? null : _handleSubmit,
      isLoading: isLoading,
      isFullWidth: true,
      size: AppButtonSize.lg,
      icon: Icons.arrow_forward_rounded,
      iconPosition: IconPosition.trailing,
    );
  }

  Widget _buildCancelLink(bool isDark, bool isLoading) {
    return Center(
      child: TextButton(
        onPressed: isLoading ? null : _handleCancel,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: Text(
          'Cancel and use a different account',
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? AppColors.mutedForegroundDark
                : AppColors.mutedForegroundLight,
          ),
        ),
      ),
    );
  }

  // Validation
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validateNickname(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a nickname';
    }
    if (value.length < 3) {
      return 'Nickname must be at least 3 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Only letters, numbers, and underscores allowed';
    }
    return null;
  }

  // Actions
  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    ref
        .read(registerProvider.notifier)
        .completeGoogleSignUp(
          name: _nameController.text.trim(),
          nickname: _nicknameController.text.trim(),
        );
  }

  void _handleCancel() {
    ref.read(registerProvider.notifier).cancelGoogleSignUp();
    context.go(AppRoutes.login);
  }

  void _showErrorSnackbar(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.surface2Dark : AppColors.gray800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
      ),
    );
  }
}
