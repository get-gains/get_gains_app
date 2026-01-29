// lib/features/auth/presentation/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';

/// Login Screen
///
/// Placeholder login screen that demonstrates design system usage
/// and provides navigation to the registration screen.
///
/// **Note**: Login functionality is not implemented - this is for
/// navigation demonstration and design showcase only.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Hidden dev bypass: tap logo 5 times to go to Unity screen
  int _logoTapCount = 0;
  DateTime? _lastTapTime;

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
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),

                  // Logo & Branding
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildHeader(isDark),
                  ),

                  const SizedBox(height: 48),

                  // Login Form
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildLoginForm(isDark),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Divider with "OR"
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildDivider(isDark),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Social Login
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildSocialLogin(isDark),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Register Link
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildRegisterLink(isDark),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        // App Logo — hidden dev bypass: tap 5 times to go to Unity screen
        GestureDetector(
          onTap: () {
            final now = DateTime.now();
            if (_lastTapTime != null &&
                now.difference(_lastTapTime!).inSeconds > 2) {
              _logoTapCount = 0;
            }
            setState(() {
              _logoTapCount++;
              _lastTapTime = now;
            });
            if (_logoTapCount >= 5) {
              _logoTapCount = 0;
              context.push(AppRoutes.unityTest);
            }
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withOpacity(0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // App Name
        Text(
          'Get Gains',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.foregroundDark
                : AppColors.foregroundLight,
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 8),

        // Tagline
        Text(
          'Your fitness journey starts here',
          style: TextStyle(
            fontSize: 16,
            color: isDark
                ? AppColors.mutedForegroundDark
                : AppColors.mutedForegroundLight,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email Field
        AppTextField(
          controller: _emailController,
          label: 'Email',
          hint: 'Enter your email',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),

        const SizedBox(height: 16),

        // Password Field
        AppTextField.password(
          controller: _passwordController,
          label: 'Password',
          hint: 'Enter your password',
          textInputAction: TextInputAction.done,
        ),

        const SizedBox(height: 12),

        // Forgot Password Link
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.push(AppRoutes.forgotPassword),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Forgot password?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Login Button (Placeholder - shows message)
        AppButton.primary(
          label: 'Sign In',
          onPressed: () {
            // Show placeholder message
            AppToast.info(
              context,
              'Login not implemented yet. Try registering!',
            );
          },
          isFullWidth: true,
          size: AppButtonSize.lg,
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  (isDark ? AppColors.borderDark : AppColors.borderLight)
                      .withOpacity(0.5),
                  isDark ? AppColors.borderDark : AppColors.borderLight,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.mutedForegroundDark
                  : AppColors.mutedForegroundLight,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  isDark ? AppColors.borderDark : AppColors.borderLight,
                  (isDark ? AppColors.borderDark : AppColors.borderLight)
                      .withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLogin(bool isDark) {
    return AppButton.outline(
      label: 'Continue with Google',
      icon: Icons.g_mobiledata_rounded,
      onPressed: () {
        AppToast.info(context, 'Login not implemented yet. Try registering!');
      },
      isFullWidth: true,
      size: AppButtonSize.lg,
    );
  }

  Widget _buildRegisterLink(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surface1Dark.withOpacity(0.5)
            : AppColors.surface1Light.withOpacity(0.8),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isDark
              ? AppColors.borderDark.withOpacity(0.5)
              : AppColors.borderLight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Don't have an account?",
            style: TextStyle(
              fontSize: 15,
              color: isDark
                  ? AppColors.mutedForegroundDark
                  : AppColors.mutedForegroundLight,
            ),
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: () => context.push(AppRoutes.register),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Sign Up',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
