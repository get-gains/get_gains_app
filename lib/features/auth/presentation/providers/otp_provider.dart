import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_error.dart';
import '../../data/auth_repository.dart';

part 'otp_provider.g.dart';

sealed class OtpState {
  const OtpState();
}

class OtpInitial extends OtpState {
  const OtpInitial();
}

class OtpSending extends OtpState {
  const OtpSending();
}

class OtpSent extends OtpState {
  const OtpSent();
}

class OtpResendCooldown extends OtpState {
  const OtpResendCooldown(this.secondsRemaining);
  final int secondsRemaining;
}

class OtpVerifying extends OtpState {
  const OtpVerifying();
}

class OtpVerified extends OtpState {
  const OtpVerified(this.resetToken);
  final String resetToken;
}

class OtpError extends OtpState {
  const OtpError(this.error);
  final AppError error;
}

@riverpod
class OtpNotifier extends _$OtpNotifier {
  Timer? _cooldownTimer;

  @override
  OtpState build() {
    ref.onDispose(() => _cooldownTimer?.cancel());
    return const OtpInitial();
  }

  Future<void> sendOtp({required String email}) async {
    state = const OtpSending();

    final authRepository = ref.read(authRepositoryProvider);
    final result = await authRepository.sendOtp(email: email);

    result.when(
      success: (_) {
        state = const OtpSent();
        _startCooldown(60);
      },
      failure: (error) {
        state = OtpError(error);
      },
    );
  }

  Future<void> verifyOtp({
    required String email,
    required String code,
  }) async {
    state = const OtpVerifying();

    final authRepository = ref.read(authRepositoryProvider);
    final result = await authRepository.verifyOtp(email: email, code: code);

    result.when(
      success: (resetToken) {
        state = OtpVerified(resetToken);
      },
      failure: (error) {
        state = OtpError(error);
      },
    );
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    int remaining = seconds;
    state = OtpResendCooldown(remaining);

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining--;
      if (remaining <= 0) {
        timer.cancel();
        state = const OtpSent();
      } else {
        state = OtpResendCooldown(remaining);
      }
    });
  }

  void clearError() {
    if (state is OtpError) {
      state = const OtpInitial();
    }
  }
}
