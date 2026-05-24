import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/logger.dart';
import '../../../../providers/auth_state_provider.dart';
import '../../data/auth_repository.dart';

part 'reset_password_provider.g.dart';

sealed class ResetPasswordState {
  const ResetPasswordState();
}

class ResetPasswordInitial extends ResetPasswordState {
  const ResetPasswordInitial();
}

class ResetPasswordLoading extends ResetPasswordState {
  const ResetPasswordLoading();
}

class ResetPasswordSuccess extends ResetPasswordState {
  const ResetPasswordSuccess();
}

class ResetPasswordError extends ResetPasswordState {
  const ResetPasswordError(this.error);
  final AppError error;
}

@riverpod
class ResetPasswordNotifier extends _$ResetPasswordNotifier {
  @override
  ResetPasswordState build() {
    return const ResetPasswordInitial();
  }

  Future<void> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {
    state = const ResetPasswordLoading();

    final authRepository = ref.read(authRepositoryProvider);
    final result = await authRepository.resetPasswordWithOtp(
      email: email,
      resetToken: resetToken,
      newPassword: newPassword,
    );

    result.when(
      success: (_) async {
        AppLogger.info(
          'Password reset successful, logging out',
          tag: 'ResetPW',
        );

        await ref.read(authStateProvider.notifier).logout();

        state = const ResetPasswordSuccess();
      },
      failure: (error) {
        state = ResetPasswordError(error);
      },
    );
  }
}
