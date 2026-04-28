import 'package:flutter_test/flutter_test.dart';
import 'package:get_gains_app/core/errors/api_error_codes.dart';
import 'package:get_gains_app/core/errors/error_messages.dart';
import 'package:get_gains_app/core/utils/app_error.dart';

void main() {
  group('errorMessageFor', () {
    test('returns curated message for authInvalidCredentials', () {
      const error = AuthError(
        message: 'Server says invalid creds',
        code: ApiErrorCode.authInvalidCredentials,
      );

      expect(errorMessageFor(error), 'Invalid email or password.');
    });

    test('returns curated message for subscriptionRequired', () {
      const error = SubscriptionRequiredError(
        message: 'Server: sub required',
        code: ApiErrorCode.subscriptionRequired,
      );

      expect(
        errorMessageFor(error),
        'This feature requires an active subscription.',
      );
    });

    test('returns curated message for coinInsufficientBalance', () {
      const error = NetworkError(
        message: 'Server: not enough coins',
        code: ApiErrorCode.coinInsufficientBalance,
        statusCode: 403,
      );

      expect(errorMessageFor(error), "You don't have enough coins.");
    });

    test('returns curated message for workoutSessionAlreadyActive', () {
      const error = NetworkError(
        message: 'Server: session already active',
        code: ApiErrorCode.workoutSessionAlreadyActive,
        statusCode: 409,
      );

      expect(errorMessageFor(error), 'A workout is already in progress.');
    });

    test('returns curated message for userUsernameTaken', () {
      const error = ValidationError(
        message: 'Server: username taken',
        code: ApiErrorCode.userUsernameTaken,
        field: 'username',
      );

      expect(errorMessageFor(error), 'That username is already taken.');
    });

    test('falls back to server message for code without curated copy', () {
      const error = NetworkError(
        message: 'Assignment not found',
        code: ApiErrorCode.assignmentNotFound,
        statusCode: 404,
      );

      // assignmentNotFound is NOT in the curated switch → server message
      expect(errorMessageFor(error), 'Assignment not found');
    });

    test(
      'falls back to server message when code is null (transport error)',
      () {
        final error = NetworkError.noConnection();

        expect(error.code, isNull);
        expect(
          errorMessageFor(error),
          'No internet connection. Please check your network.',
        );
      },
    );
  });

  group('errorToastFor', () {
    test('returns title + body for AuthError', () {
      const error = AuthError(
        message: 'Server msg',
        code: ApiErrorCode.authEmailNotVerified,
      );

      final result = errorToastFor(error);
      expect(result.title, 'Authentication Error');
      expect(result.body, 'Please verify your email before signing in.');
    });

    test('returns title + body for SubscriptionRequiredError', () {
      const error = SubscriptionRequiredError(
        message: 'Server msg',
        code: ApiErrorCode.subscriptionTierInsufficient,
      );

      final result = errorToastFor(error);
      expect(result.title, 'Subscription Required');
      expect(result.body, 'This feature requires a higher-tier plan.');
    });

    test('returns generic title for UnknownError', () {
      const error = UnknownError(message: 'Something broke');

      final result = errorToastFor(error);
      expect(result.title, 'Error');
      expect(result.body, 'Something broke');
    });
  });
}
