import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_gains_app/services/api/interceptors.dart';
import 'package:get_gains_app/services/storage/secure_storage_service.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// Minimal in-memory [SecureStorageService] for testing.
///
/// Stubs only the token methods needed by [AuthInterceptor].
class FakeSecureStorageService extends Fake implements SecureStorageService {
  String? accessToken;
  String? refreshToken;

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiry,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }
}

/// A spy [ErrorInterceptorHandler] that records what was called.
class SpyErrorHandler extends Fake implements ErrorInterceptorHandler {
  DioException? nextError;
  Response<dynamic>? resolvedResponse;
  bool nextCalled = false;
  bool resolveCalled = false;

  @override
  void next(DioException err) {
    nextError = err;
    nextCalled = true;
  }

  @override
  void resolve(Response<dynamic> response) {
    resolvedResponse = response;
    resolveCalled = true;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a [DioException] with a 401 response carrying the given [code]
/// in the standard `{errors: [{code, message}]}` envelope.
DioException _make401({
  required String path,
  String? code,
  String message = 'Unauthorized',
}) {
  final responseData = <String, dynamic>{
    'data': null,
    'errors': [
      <String, dynamic>{?'code': code, 'message': message},
    ],
  };

  final options = RequestOptions(path: path);
  return DioException(
    requestOptions: options,
    response: Response(
      requestOptions: options,
      statusCode: HttpStatus.unauthorized,
      data: responseData,
    ),
    type: DioExceptionType.badResponse,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakeSecureStorageService storage;
  late int refreshCallCount;
  late int authFailureCallCount;
  late AuthInterceptor interceptor;
  late SpyErrorHandler handler;

  setUp(() {
    storage = FakeSecureStorageService()
      ..accessToken = 'old-access'
      ..refreshToken = 'old-refresh';

    refreshCallCount = 0;
    authFailureCallCount = 0;

    interceptor = AuthInterceptor(
      secureStorage: storage,
      onTokenRefresh: () async {
        refreshCallCount++;
        return false; // doesn't matter for most tests
      },
      onAuthFailure: () => authFailureCallCount++,
    );

    handler = SpyErrorHandler();
  });

  group('AuthInterceptor code-aware refresh', () {
    test(
      '401 with AUTH_INVALID_CREDENTIALS on login does NOT trigger refresh',
      () async {
        final err = _make401(
          path: '/auth/login',
          code: 'AUTH_INVALID_CREDENTIALS',
          message: 'Invalid email or password.',
        );

        interceptor.onError(err, handler);

        // Give the async handler body a chance to complete.
        await Future<void>.delayed(Duration.zero);

        expect(
          refreshCallCount,
          0,
          reason: 'Should not attempt refresh for bad credentials',
        );
        expect(
          authFailureCallCount,
          0,
          reason: 'Login failures should not force logout',
        );
        expect(
          handler.nextCalled,
          isTrue,
          reason: 'Error should still propagate to the caller',
        );
      },
    );

    test('401 with AUTH_TOKEN_EXPIRED triggers refresh attempt', () async {
      final err = _make401(
        path: '/api/users/profile',
        code: 'AUTH_TOKEN_EXPIRED',
        message: 'Token expired',
      );

      interceptor.onError(err, handler);

      await Future<void>.delayed(Duration.zero);

      expect(
        refreshCallCount,
        1,
        reason: 'Should attempt refresh for expired token',
      );
    });

    test('401 with AUTH_SESSION_EXPIRED triggers refresh attempt', () async {
      final err = _make401(
        path: '/api/workout/sessions',
        code: 'AUTH_SESSION_EXPIRED',
        message: 'Session expired',
      );

      interceptor.onError(err, handler);

      await Future<void>.delayed(Duration.zero);

      expect(
        refreshCallCount,
        1,
        reason: 'Should attempt refresh for expired session',
      );
    });

    test(
      '401 with AUTH_TOKEN_INVALID on a normal endpoint skips refresh and triggers auth failure',
      () async {
        final err = _make401(
          path: '/api/users/profile',
          code: 'AUTH_TOKEN_INVALID',
          message: 'Token invalid',
        );

        interceptor.onError(err, handler);

        await Future<void>.delayed(Duration.zero);

        expect(
          refreshCallCount,
          0,
          reason: 'Should not refresh an invalid token',
        );
        expect(
          authFailureCallCount,
          1,
          reason: 'Should trigger auth failure for unrecoverable 401',
        );
        expect(handler.nextCalled, isTrue);
      },
    );

    test(
      '401 with no code (legacy / non-JSON response) defaults to refresh',
      () async {
        // Simulate a 401 with an envelope that has no `code` field.
        final err = _make401(
          path: '/api/users/profile',
          code: null,
          message: 'Unauthorized',
        );

        interceptor.onError(err, handler);

        await Future<void>.delayed(Duration.zero);

        expect(
          refreshCallCount,
          1,
          reason: 'Legacy 401s should default to refresh attempt',
        );
      },
    );

    test(
      '401 on /auth/refresh propagates without retry (avoids loop)',
      () async {
        final err = _make401(
          path: '/auth/refresh',
          code: 'AUTH_REFRESH_FAILED',
          message: 'Refresh failed',
        );

        interceptor.onError(err, handler);

        await Future<void>.delayed(Duration.zero);

        expect(refreshCallCount, 0, reason: 'Must not recurse into refresh');
        expect(
          authFailureCallCount,
          1,
          reason: 'Refresh path failure triggers logout',
        );
        expect(handler.nextCalled, isTrue);
      },
    );
  });
}
