import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../providers/reset_password_provider.dart';

/// Reset Password Screen
///
/// Shown after user arrives from deep link with recovery token.
/// Provides new password + confirm password fields.
/// On success, logs out user and redirects to login.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  final _confirmFocusNode = FocusNode();

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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmFocusNode.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    ref
        .read(resetPasswordProvider.notifier)
        .resetPassword(newPassword: _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final state = ref.watch(resetPasswordProvider);

    // Listen for state changes
    ref.listen(resetPasswordProvider, (_, next) {
      if (next is ResetPasswordSuccess) {
        AppToast.success(
          context,
          'Password reset successfully! Please log in.',
        );
        context.go(AppRoutes.login);
      } else if (next is ResetPasswordError) {
        AppToast.error(context, next.error.message);
      }
    });

    // Token missing state — use AppErrorState
    if (state is ResetPasswordTokenMissing) {
      return _buildTokenMissingState(isDark, size);
    }

    final isLoading = state is ResetPasswordLoading;

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
              child: Column(
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
                        color:
                            (isDark
                                    ? AppColors.primaryDark
                                    : AppColors.primaryLight)
                                .withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_outline_rounded,
                        size: 40,
                        color: isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight,
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
                        'Set new password',
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
                        'Enter your new password below. Make sure it\'s strong and unique.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacing8),

                  // Form
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // New Password
                            AppTextField.password(
                              controller: _passwordController,
                              label: 'New Password',
                              hint: 'Enter your new password',
                              focusNode: _passwordFocusNode,
                              textInputAction: TextInputAction.next,
                              enabled: !isLoading,
                              onSubmitted: (_) =>
                                  _confirmFocusNode.requestFocus(),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password is required';
                                }
                                if (value.length < 8) {
                                  return 'Password must be at least 8 characters';
                                }
                                if (!RegExp(r'[A-Z]').hasMatch(value)) {
                                  return 'Must contain at least 1 capital letter';
                                }
                                if (!RegExp(
                                  r'[!@#$%^&*()_+=\[\]{};:"|,.<>/?`~\\-]',
                                ).hasMatch(value)) {
                                  return 'Must contain at least 1 special character';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: AppTheme.spacing4),

                            // Confirm Password
                            AppTextField.password(
                              controller: _confirmPasswordController,
                              label: 'Confirm Password',
                              hint: 'Confirm your new password',
                              focusNode: _confirmFocusNode,
                              textInputAction: TextInputAction.done,
                              enabled: !isLoading,
                              onSubmitted: (_) => _onSubmit(),
                              validator: (value) {
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: AppTheme.spacing3),

                            // Password requirements hint
                            Container(
                              padding: const EdgeInsets.all(AppTheme.spacing4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.surface1Dark.withOpacity(0.5)
                                    : AppColors.surface1Light,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd,
                                ),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.borderDark.withOpacity(0.5)
                                      : AppColors.borderLight,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Password requirements:',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: isDark
                                          ? AppColors.mutedForegroundDark
                                          : AppColors.mutedForegroundLight,
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.spacing2),
                                  _buildRequirement(
                                    isDark,
                                    'At least 8 characters',
                                  ),
                                  const SizedBox(height: AppTheme.spacing1),
                                  _buildRequirement(
                                    isDark,
                                    'At least 1 capital letter',
                                  ),
                                  const SizedBox(height: AppTheme.spacing1),
                                  _buildRequirement(
                                    isDark,
                                    'At least 1 special character',
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: AppTheme.spacing8),

                            // Submit Button
                            AppButton.primary(
                              label: 'Reset Password',
                              onPressed: isLoading ? null : _onSubmit,
                              isFullWidth: true,
                              size: AppButtonSize.lg,
                              isLoading: isLoading,
                              icon: Icons.check_rounded,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTokenMissingState(bool isDark, Size screenSize) {
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing6),
            child: AppErrorState(
              title: 'Invalid Reset Link',
              description:
                  'This password reset link is invalid or has expired.\nPlease request a new one.',
              icon: Icons.link_off_rounded,
              size: AppEmptyStateSize.lg,
              retryLabel: 'Request New Link',
              onRetry: () => context.go(AppRoutes.forgotPassword),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequirement(bool isDark, String text) {
    return Row(
      children: [
        Icon(
          Icons.circle,
          size: 6,
          color: isDark
              ? AppColors.mutedForegroundDark
              : AppColors.mutedForegroundLight,
        ),
        const SizedBox(width: AppTheme.spacing2),
        Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(
            color: isDark
                ? AppColors.mutedForegroundDark
                : AppColors.mutedForegroundLight,
          ),
        ),
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
