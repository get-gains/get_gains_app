import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../providers/otp_provider.dart';

/// Forgot Password Screen
///
/// Simple screen with email input.
/// Calls POST /auth/send-otp via OtpNotifier.
/// On success, navigates to the Enter OTP screen.
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

    await ref
        .read(otpProvider.notifier)
        .sendOtp(email: _emailController.text.trim());

    if (!mounted) return;

    final state = ref.read(otpProvider);
    if (state is OtpSent) {
      context.goNamed(
        'enter-otp',
        queryParameters: {'email': _emailController.text.trim()},
      );
    } else if (state is OtpError) {
      AppToast.error(context, state.error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final otpState = ref.watch(otpProvider);
    final isLoading = otpState is OtpSending;

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
              child: _buildEmailForm(isDark, isLoading),
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
                        'Enter your email address and we\'ll send you a 6-character verification code.',
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
                      label: 'Send Code',
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
