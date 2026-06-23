// lib/features/auth/presentation/screens/register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/api_error_codes.dart';
import '../../../../core/errors/error_messages.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_error.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../providers/register_provider.dart';

/// Register Screen
///
/// Full registration screen with:
/// - Email/password registration form
/// - Google sign-up option
/// - Form validation
/// - Loading states
/// - Error handling
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  final _nameFocus = FocusNode();
  final _nicknameFocus = FocusNode();

  bool _acceptedTerms = false;
  String _passwordValue = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _animationController.forward();

    // Listen to password changes for requirements display
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    setState(() {
      _passwordValue = _passwordController.text;
    });
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _nicknameController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
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
      if (next is RegisterEmailVerificationPending) {
        // Navigate to email verification code entry
        context.go(
          '${AppRoutes.emailVerification}?email=${Uri.encodeComponent(next.email)}',
        );
      } else if (next is RegisterSuccess) {
        // Direct success (e.g., Google OAuth with auto-verified email)
        context.go(AppRoutes.home);
      } else if (next is RegisterGooglePendingProfile) {
        // Navigate to complete profile
        context.go(AppRoutes.completeProfile);
      } else if (next is RegisterError) {
        _showRegisterError(next.error);
      }
    });

    final isLoading = registerState is RegisterLoading;

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
                    const SizedBox(height: 32),

                    // Back Button & Header
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildHeader(context, isDark),
                    ),

                    const SizedBox(height: 32),

                    // Registration Form
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildForm(isDark, isLoading),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Terms & Conditions
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildTermsCheckbox(isDark),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Register Button
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildRegisterButton(isDark, isLoading),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Divider
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildDivider(isDark),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Google Sign Up
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildGoogleSignUp(isDark, isLoading),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Login Link
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildLoginLink(isDark),
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

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back Button
        Row(
          children: [
            _BackButton(onPressed: () => context.pop(), isDark: isDark),
          ],
        ),

        const SizedBox(height: 24),

        // Title with accent
        Row(
          children: [
            Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.foregroundDark
                          : AppColors.foregroundLight,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Start your fitness journey today',
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildForm(bool isDark, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Name and Nickname Row
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _nameController,
                focusNode: _nameFocus,
                label: 'Full Name',
                hint: 'John Doe',
                prefixIcon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                enabled: !isLoading,
                validator: _validateName,
                onSubmitted: (_) => _nicknameFocus.requestFocus(),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Nickname
        AppTextField(
          controller: _nicknameController,
          focusNode: _nicknameFocus,
          label: 'Nickname',
          hint: 'johnd',
          helperText: 'This will be visible to others',
          prefixIcon: Icons.alternate_email_rounded,
          textInputAction: TextInputAction.next,
          enabled: !isLoading,
          validator: _validateNickname,
          onSubmitted: (_) => _emailFocus.requestFocus(),
        ),

        const SizedBox(height: 16),

        // Email
        AppTextField(
          controller: _emailController,
          focusNode: _emailFocus,
          label: 'Email',
          hint: 'john@example.com',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          enabled: !isLoading,
          validator: _validateEmail,
          onSubmitted: (_) => _passwordFocus.requestFocus(),
        ),

        const SizedBox(height: 16),

        // Password
        AppTextField.password(
          controller: _passwordController,
          focusNode: _passwordFocus,
          label: 'Password',
          hint: 'Min. 8 characters',
          textInputAction: TextInputAction.next,
          enabled: !isLoading,
          validator: _validatePassword,
          onSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
        ),

        const SizedBox(height: 16),

        // Confirm Password
        AppTextField.password(
          controller: _confirmPasswordController,
          focusNode: _confirmPasswordFocus,
          label: 'Confirm Password',
          hint: 'Re-enter your password',
          textInputAction: TextInputAction.done,
          enabled: !isLoading,
          validator: _validateConfirmPassword,
          onSubmitted: (_) => _handleRegister(),
        ),

        // Password Requirements
        const SizedBox(height: 12),
        _PasswordRequirements(password: _passwordValue),
      ],
    );
  }

  Widget _buildTermsCheckbox(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: _acceptedTerms,
              onChanged: (value) {
                setState(() => _acceptedTerms = value ?? false);
              },
              activeColor: isDark
                  ? AppColors.primaryDark
                  : AppColors.primaryLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton(bool isDark, bool isLoading) {
    return AppButton.primary(
      label: 'Create Account',
      onPressed: isLoading ? null : _handleRegister,
      isLoading: isLoading,
      isFullWidth: true,
      size: AppButtonSize.lg,
      icon: Icons.arrow_forward_rounded,
      iconPosition: IconPosition.trailing,
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

  Widget _buildGoogleSignUp(bool isDark, bool isLoading) {
    return _GoogleSignInButton(
      onPressed: isLoading ? null : _handleGoogleSignUp,
      isLoading: isLoading,
      isDark: isDark,
    );
  }

  Widget _buildLoginLink(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account?',
          style: TextStyle(
            fontSize: 15,
            color: isDark
                ? AppColors.mutedForegroundDark
                : AppColors.mutedForegroundLight,
          ),
        ),
        TextButton(
          onPressed: () => context.pop(),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Sign In',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            ),
          ),
        ),
      ],
    );
  }

  // Validation Methods
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
      return 'Only letters, numbers, and underscores';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.+]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain an uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain a lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain a number';
    }
    if (!value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain a special character';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    // Also validate the confirm password has special character
    if (!value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain a special character';
    }
    return null;
  }

  // ── Error handling ──────────────────────────────────────────────

  void _showRegisterError(AppError error) {
    final message = errorMessageFor(error);

    switch (error.code) {
      // Email already registered — offer to sign in instead
      case ApiErrorCode.authEmailAlreadyExists:
        AppToast.error(
          context,
          message,
          actionLabel: 'Sign In',
          action: () => context.pop(),
        );
        _emailFocus.requestFocus();

      // Weak password — highlight the password field
      case ApiErrorCode.authWeakPassword:
        AppToast.error(context, message);
        _passwordFocus.requestFocus();

      // Nickname already taken — highlight the nickname field
      case ApiErrorCode.userUsernameTaken:
        AppToast.error(context, message);
        _nicknameFocus.requestFocus();

      // Email taken (distinct from "already exists" in some flows)
      case ApiErrorCode.userEmailTaken:
        AppToast.error(context, message);
        _emailFocus.requestFocus();

      default:
        AppToast.error(context, message);
    }
  }

  // Action Methods
  void _handleRegister() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptedTerms) {
      AppToast.error(context, 'Please accept the Terms of Service');
      return;
    }

    ref
        .read(registerProvider.notifier)
        .registerWithEmailPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          nickname: _nicknameController.text.trim(),
        );
  }

  void _handleGoogleSignUp() {
    ref.read(registerProvider.notifier).signInWithGoogle();
  }
}

// ============================================================
// HELPER WIDGETS
// ============================================================

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed, required this.isDark});

  final VoidCallback onPressed;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surface1Dark : AppColors.surface1Light,
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
            color: isDark
                ? AppColors.foregroundDark
                : AppColors.foregroundLight,
          ),
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatefulWidget {
  const _GoogleSignInButton({
    required this.onPressed,
    required this.isLoading,
    required this.isDark,
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDark;

  @override
  State<_GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<_GoogleSignInButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: AppTheme.durationFast,
          child: AnimatedContainer(
            duration: AppTheme.durationFast,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? (_isHovered
                        ? AppColors.surface2Dark
                        : AppColors.surface1Dark)
                  : (_isHovered ? AppColors.gray100 : AppColors.white),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: widget.isDark
                    ? AppColors.borderDark
                    : AppColors.borderLight,
                width: 1.5,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Google Logo
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Image.network(
                    'https://www.google.com/favicon.ico',
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.g_mobiledata_rounded,
                      size: 20,
                      color: widget.isDark
                          ? AppColors.foregroundDark
                          : AppColors.foregroundLight,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Continue with Google',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.isDark
                        ? AppColors.foregroundDark
                        : AppColors.foregroundLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordRequirements extends StatelessWidget {
  const _PasswordRequirements({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final requirements = [
      _Requirement('At least 8 characters', password.length >= 8),
      _Requirement(
        'Contains uppercase letter',
        password.contains(RegExp(r'[A-Z]')),
      ),
      _Requirement(
        'Contains lowercase letter',
        password.contains(RegExp(r'[a-z]')),
      ),
      _Requirement('Contains number', password.contains(RegExp(r'[0-9]'))),
      _Requirement(
        'Contains special character',
        password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]')),
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: requirements.map((req) {
        final isMet = req.isMet;
        return AnimatedContainer(
          duration: AppTheme.durationFast,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isMet
                ? AppColors.success.withOpacity(0.1)
                : (isDark ? AppColors.surface1Dark : AppColors.surface1Light),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(
              color: isMet
                  ? AppColors.success.withOpacity(0.3)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isMet ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 12,
                color: isMet
                    ? AppColors.success
                    : (isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight),
              ),
              const SizedBox(width: 4),
              Text(
                req.label,
                style: TextStyle(
                  fontSize: 11,
                  color: isMet
                      ? AppColors.success
                      : (isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForegroundLight),
                  fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _Requirement {
  const _Requirement(this.label, this.isMet);
  final String label;
  final bool isMet;
}
