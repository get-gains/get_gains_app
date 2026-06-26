import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_error.dart';
import '../../../../providers/router_provider.dart';
import '../../../../core/formatters/text_formatters.dart';
import '../../../../widgets/widgets.dart';
import '../providers/otp_provider.dart';

class EnterOtpScreen extends ConsumerStatefulWidget {
  const EnterOtpScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<EnterOtpScreen> createState() => _EnterOtpScreenState();
}

class _EnterOtpScreenState extends ConsumerState<EnterOtpScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _autoSubmitted = false;

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
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code =>
      _controllers.map((c) => c.text).join().toUpperCase();

  bool get _isComplete => _code.length == 6;

  void _onChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    if (_isComplete && !_autoSubmitted) {
      _autoSubmitted = true;
      Future.delayed(const Duration(milliseconds: 300), _onSubmit);
    }
  }

  Future<void> _onSubmit() async {
    if (!_isComplete) return;

    await ref.read(otpProvider.notifier).verifyOtp(
          email: widget.email,
          code: _code,
        );
  }

  Future<void> _onResend() async {
    await ref.read(otpProvider.notifier).sendOtp(email: widget.email);
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    final masked = name.length > 2
        ? '${name[0]}${'*' * (name.length - 2)}${name[name.length - 1]}'
        : name;
    return '$masked@$domain';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final state = ref.watch(otpProvider);

    ref.listen(otpProvider, (_, next) {
      if (next is OtpVerified) {
        AppToast.success(context, 'Code verified!');
        context.goNamed(
          'reset-password',
          queryParameters: {
            'email': widget.email,
            'token': next.resetToken,
          },
        );
      } else if (next is OtpError) {
        final message = next.error is ValidationError
            ? (next.error as ValidationError).message
            : next.error.message;
        AppToast.error(context, message);
      }
    });

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppTheme.spacing4),
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
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: (isDark
                                ? AppColors.primaryDark
                                : AppColors.primaryLight)
                            .withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mark_email_read_rounded,
                        size: 40,
                        color: isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing6),
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
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing2),
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: RichText(
                        text: TextSpan(
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isDark
                                ? AppColors.mutedForegroundDark
                                : AppColors.mutedForegroundLight,
                          ),
                          children: [
                            const TextSpan(
                              text: 'We sent a 6-character code to ',
                            ),
                            TextSpan(
                              text: _maskEmail(widget.email),
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: isDark
                                    ? AppColors.foregroundDark
                                    : AppColors.foregroundLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                            return SizedBox(
                              width: 56,
                              height: 56,
                            child: TextField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              keyboardType: TextInputType.visiblePassword,
                              textInputAction: index == 5
                                  ? TextInputAction.done
                                  : TextInputAction.next,
                              style: AppTextStyles.headlineMedium.copyWith(
                                color: isDark
                                    ? AppColors.foregroundDark
                                    : AppColors.foregroundLight,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0,
                              ),
                              textCapitalization: TextCapitalization.characters,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[a-zA-Z0-9]'),
                                ),
                                UpperCaseTextFormatter(),
                              ],
                              cursorColor: isDark
                                  ? AppColors.primaryDark
                                  : AppColors.primaryLight,
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: isDark
                                    ? AppColors.surface1Dark.withOpacity(0.5)
                                    : AppColors.surface1Light,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMd,
                                  ),
                                  borderSide: BorderSide(
                                    color: _controllers[index].text.isNotEmpty
                                        ? (isDark
                                            ? AppColors.primaryDark
                                            : AppColors.primaryLight)
                                        : (isDark
                                            ? AppColors.borderDark
                                            : AppColors.borderLight),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMd,
                                  ),
                                  borderSide: BorderSide(
                                    color: _controllers[index].text.isNotEmpty
                                        ? (isDark
                                            ? AppColors.primaryDark
                                            : AppColors.primaryLight)
                                        : (isDark
                                            ? AppColors.borderDark
                                                .withOpacity(0.5)
                                            : AppColors.borderLight),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMd,
                                  ),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? AppColors.primaryDark
                                        : AppColors.primaryLight,
                                    width: 2,
                                  ),
                                ),
                              ),
                              onChanged: (value) =>
                                  _onChanged(value, index),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing2),
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildResendRow(isDark, state),
                    ),
                  ),
                  if (state is OtpVerifying || state is OtpSending) ...[
                    const SizedBox(height: AppTheme.spacing6),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResendRow(bool isDark, OtpState state) {
    if (state is OtpResendCooldown) {
      return Text(
        'Resend in ${state.secondsRemaining}s',
        style: AppTextStyles.bodySmall.copyWith(
          color: isDark
              ? AppColors.mutedForegroundDark
              : AppColors.mutedForegroundLight,
        ),
        textAlign: TextAlign.center,
      );
    }

    if (state is OtpSending) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: _onResend,
        child: Text(
          'Resend code',
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(bool isDark) {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.forgotPassword),
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
