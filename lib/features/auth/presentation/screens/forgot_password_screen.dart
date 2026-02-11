import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../providers/register_provider.dart';

/// Forgot Password Screen
///
/// Simple screen with email input.
/// Calls POST /auth/send-recovery-email via PasswordRecoveryNotifier.
/// On success, shows confirmation message with option to go back to login.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(passwordRecoveryProvider.notifier)
        .sendRecoveryEmail(email: _emailController.text.trim());

    if (success && mounted) {
      setState(() => _emailSent = true);
      // Re-trigger animation for the success state
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final recoveryState = ref.watch(passwordRecoveryProvider);
    final isLoading = recoveryState is AsyncLoading;

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
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing6,
              ),
              child: _emailSent
                  ? _buildSuccessState(isDark)
                  : _buildEmailForm(isDark, isLoading),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm(bool isDark, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppTheme.spacing4),

        // Back button
        SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildBackButton(isDark),
            ),
          ),
        ),

        const SizedBox(height: AppTheme.spacing8),

        // Icon
        FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                  .withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_reset_rounded,
              size: 40,
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            ),
          ),
        ),

        const SizedBox(height: AppTheme.spacing6),

        // Title
        SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              'Reset your password',
              style: AppTextStyles.headlineLarge.copyWith(
                color: isDark
                    ? AppColors.foregroundDark
                    : AppColors.foregroundLight,
              ),
            ),
          ),
        ),

        const SizedBox(height: AppTheme.spacing2),

        // Subtitle
        SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
            ),
          ),
        ),

        const SizedBox(height: AppTheme.spacing8),

        // Email Form
        SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'your@email.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    enabled: !isLoading,
                    onSubmitted: (_) => _onSubmit(),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(
                        r'^[^@]+@[^@]+\.[^@]+$',
                      ).hasMatch(value.trim())) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppTheme.spacing6),

                  AppButton.primary(
                    label: 'Send Reset Link',
                    onPressed: isLoading ? null : _onSubmit,
                    isFullWidth: true,
                    size: AppButtonSize.lg,
                    isLoading: isLoading,
                    icon: Icons.send_rounded,
                  ),

                  const SizedBox(height: AppTheme.spacing4),

                  AppButton.ghost(
                    label: 'Back to Login',
                    onPressed: () => context.go(AppRoutes.login),
                    isFullWidth: true,
                    icon: Icons.arrow_back_rounded,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: AppTheme.spacing12),

        // Icon
        FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.success.withOpacity(0.2),
                  AppColors.success.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.success.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.mark_email_read_rounded,
                  size: 56,
                  color: AppColors.success,
                ),
                Positioned(
                  bottom: 24,
                  right: 24,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppTheme.spacing8),

        // Title
        SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              'Check your email',
              style: AppTextStyles.headlineLarge.copyWith(
                color: isDark
                    ? AppColors.foregroundDark
                    : AppColors.foregroundLight,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),

        const SizedBox(height: AppTheme.spacing3),

        // Description
        SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              'We sent a password reset link to\n${_emailController.text.trim()}',
              style: AppTextStyles.bodyLarge.copyWith(
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),

        const SizedBox(height: AppTheme.spacing3),

        // Info hint
        SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacing4),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surface1Dark.withOpacity(0.5)
                    : AppColors.surface1Light,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: isDark
                      ? AppColors.borderDark.withOpacity(0.5)
                      : AppColors.borderLight,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                  const SizedBox(width: AppTheme.spacing3),
                  Expanded(
                    child: Text(
                      'Don\'t forget to check your spam folder.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForegroundLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: AppTheme.spacing8),

        // Actions
        SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppButton.primary(
                  label: 'Back to Login',
                  onPressed: () => context.go(AppRoutes.login),
                  isFullWidth: true,
                  size: AppButtonSize.lg,
                  icon: Icons.arrow_back_rounded,
                ),

                const SizedBox(height: AppTheme.spacing3),

                AppButton.ghost(
                  label: 'Didn\'t receive the email? Try again',
                  onPressed: () => setState(() => _emailSent = false),
                  isFullWidth: true,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppTheme.spacing12),
      ],
    );
  }

  Widget _buildBackButton(bool isDark) {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.login),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surface1Dark.withOpacity(0.8)
              : AppColors.surface1Light,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isDark
                ? AppColors.borderDark.withOpacity(0.5)
                : AppColors.borderLight,
          ),
        ),
        child: Icon(
          Icons.arrow_back_rounded,
          size: 20,
          color: isDark ? AppColors.foregroundDark : AppColors.foregroundLight,
        ),
      ),
    );
  }
}
