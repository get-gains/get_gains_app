import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/logger.dart';
import '../../../../providers/auth_state_provider.dart';
import '../../../../services/storage/secure_storage_service.dart';
import '../../data/auth_repository.dart';

part 'reset_password_provider.g.dart';

/// Reset Password State
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

class ResetPasswordTokenMissing extends ResetPasswordState {
  const ResetPasswordTokenMissing();
}

/// Reset Password Notifier
///
/// Manages the password reset flow after user arrives from deep link.
///
/// Flow:
/// 1. Deep link stores recovery token in SecureStorage
/// 2. User enters new password + confirm password
/// 3. This provider calls POST /auth/reset-password with Bearer token
/// 4. On success: clears all tokens, logs out, navigates to login
///
/// Usage:
/// ```dart
/// ref.read(resetPasswordNotifierProvider.notifier).resetPassword(
///   newPassword: 'NewPass123!',
/// );
/// ```
@riverpod
class ResetPasswordNotifier extends _$ResetPasswordNotifier {
  @override
  ResetPasswordState build() {
    // Check if recovery token exists
    _checkRecoveryToken();
    return const ResetPasswordInitial();
  }

  Future<void> _checkRecoveryToken() async {
    final secureStorage = ref.read(secureStorageServiceProvider);
    final token = await secureStorage.getRecoveryToken();
    if (token == null) {
      state = const ResetPasswordTokenMissing();
    }
  }

  /// Reset password using the stored recovery token
  Future<void> resetPassword({required String newPassword}) async {
    state = const ResetPasswordLoading();

    final secureStorage = ref.read(secureStorageServiceProvider);
    final recoveryToken = await secureStorage.getRecoveryToken();

    if (recoveryToken == null) {
      state = const ResetPasswordError(
        AuthError(
          message:
              'Recovery session expired. Please request a new password reset.',
          code: 'NO_RECOVERY_TOKEN',
        ),
      );
      return;
    }

    final authRepository = ref.read(authRepositoryProvider);
    final result = await authRepository.resetPassword(
      newPassword: newPassword,
      recoveryAccessToken: recoveryToken,
    );

    result.when(
      success: (_) async {
        AppLogger.info(
          'Password reset successful, logging out',
          tag: 'ResetPW',
        );

        // Clear recovery tokens
        await secureStorage.clearRecoveryTokens();

        // Logout the user (clear all auth state)
        await ref.read(authStateProvider.notifier).logout();

        state = const ResetPasswordSuccess();
      },
      failure: (error) {
        state = ResetPasswordError(error);
      },
    );
  }
}
