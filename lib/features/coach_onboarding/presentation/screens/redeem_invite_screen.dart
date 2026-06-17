import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:get_gains_app/core/theme/app_colors.dart';
import 'package:get_gains_app/core/utils/app_error.dart';
import 'package:get_gains_app/core/utils/logger.dart';
import 'package:get_gains_app/providers/router_provider.dart';
import 'package:get_gains_app/widgets/widgets.dart';

import '../providers/coach_invite_provider.dart';

/// Screen where a user enters a 6-digit coach invitation code.
class RedeemInviteScreen extends ConsumerStatefulWidget {
  const RedeemInviteScreen({super.key});

  @override
  ConsumerState<RedeemInviteScreen> createState() =>
      _RedeemInviteScreenState();
}

class _RedeemInviteScreenState extends ConsumerState<RedeemInviteScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();

    if (code.length != 6 || int.tryParse(code) == null) {
      setState(() => _errorText = 'Enter a valid 6-digit code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final repository = ref.read(coachInviteRepositoryProvider);
    final result = await repository.verifyInvite(code);

    if (!mounted) return;

    setState(() => _isLoading = false);

    result.when(
      success: (_) {
        context.push(AppRoutes.coachProfileSetup, extra: code);
      },
      failure: (error) {
        setState(() => _errorText = _formatError(error));
        AppLogger.warning(
          'Invite verification failed: ${error.message}',
          tag: 'RedeemInvite',
        );
      },
    );
  }

  String _formatError(AppError error) {
    if (error is ValidationError) {
      return error.message;
    }
    return error.message;
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
        title: const Text('Redeem Invite'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your coach invite code',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'If you received a 6-digit invite code by email, enter it below to set up your coach profile.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
              const SizedBox(height: 32),
              AppTextField(
                controller: _codeController,
                label: 'Invite Code',
                hint: '000000',
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                maxLength: 6,
                errorText: _errorText,
                enabled: !_isLoading,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onSubmitted: (_) => _verifyCode(),
              ),
              const SizedBox(height: 24),
              AppButton.primary(
                label: 'Continue',
                isFullWidth: true,
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _verifyCode,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
