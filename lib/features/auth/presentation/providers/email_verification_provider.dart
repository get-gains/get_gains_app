import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_error.dart';
import '../../data/auth_repository.dart';

part 'email_verification_provider.g.dart';

sealed class EmailVerificationState {
  const EmailVerificationState();
}

class EmailVerificationInitial extends EmailVerificationState {
  const EmailVerificationInitial();
}

class EmailVerificationSending extends EmailVerificationState {
  const EmailVerificationSending();
}

class EmailVerificationSent extends EmailVerificationState {
  const EmailVerificationSent();
}

class EmailVerificationResendCooldown extends EmailVerificationState {
  const EmailVerificationResendCooldown(this.secondsRemaining);
  final int secondsRemaining;
}

class EmailVerificationVerifying extends EmailVerificationState {
  const EmailVerificationVerifying();
}

class EmailVerificationVerified extends EmailVerificationState {
  const EmailVerificationVerified();
}

class EmailVerificationError extends EmailVerificationState {
  const EmailVerificationError(this.error);
  final AppError error;
}

@riverpod
class EmailVerificationNotifier extends _$EmailVerificationNotifier {
  Timer? _cooldownTimer;

  @override
  EmailVerificationState build() {
    ref.onDispose(() => _cooldownTimer?.cancel());
    return const EmailVerificationInitial();
  }

  Future<void> sendVerificationCode({required String email}) async {
    state = const EmailVerificationSending();

    final authRepository = ref.read(authRepositoryProvider);
    final result =
        await authRepository.sendEmailVerificationCode(email: email);

    result.when(
      success: (_) {
        state = const EmailVerificationSent();
        _startCooldown(60);
      },
      failure: (error) {
        state = EmailVerificationError(error);
      },
    );
  }

  Future<void> verifyCode({
    required String email,
    required String code,
  }) async {
    state = const EmailVerificationVerifying();

    final authRepository = ref.read(authRepositoryProvider);
    final result =
        await authRepository.verifyEmailCode(email: email, code: code);

    result.when(
      success: (_) {
        state = const EmailVerificationVerified();
      },
      failure: (error) {
        state = EmailVerificationError(error);
      },
    );
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    int remaining = seconds;
    state = EmailVerificationResendCooldown(remaining);

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining--;
      if (remaining <= 0) {
        timer.cancel();
        state = const EmailVerificationSent();
      } else {
        state = EmailVerificationResendCooldown(remaining);
      }
    });
  }

  void clearError() {
    if (state is EmailVerificationError) {
      state = const EmailVerificationInitial();
    }
  }
}
