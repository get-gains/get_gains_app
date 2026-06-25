import 'package:equatable/equatable.dart';

import '../errors/api_error_codes.dart';

/// Application Error Types
///
/// Centralized error handling with typed errors for different failure scenarios.
/// Use with `Result<T, AppError>` for consistent error handling across the app.
///
/// [code] carries the server's typed [ApiErrorCode] when the error originated
/// from the API. It is `null` for pure transport / local errors.
///
/// [transportCode] carries client-side transport labels like `'NO_CONNECTION'`,
/// `'TIMEOUT'`, `'CANCELLED'` etc. — these have no server counterpart.
sealed class AppError extends Equatable {
  const AppError({
    required this.message,
    this.code,
    this.transportCode,
    this.originalError,
  });

  /// Human-readable error description (may come from the server or be generated
  /// locally).
  final String message;

  /// Typed server error code parsed from the `{ errors[].code }` envelope.
  /// `null` when the error is purely local / transport-level.
  final ApiErrorCode? code;

  /// Client-side transport label (`'NO_CONNECTION'`, `'TIMEOUT'`, etc.).
  /// `null` when the error came from the server with a typed [code].
  final String? transportCode;

  final Object? originalError;

  @override
  List<Object?> get props => [message, code, transportCode, originalError];
}

/// Network-related errors (API calls, connectivity)
final class NetworkError extends AppError {
  const NetworkError({
    required super.message,
    super.code,
    super.transportCode,
    super.originalError,
    this.statusCode,
    this.meta,
  });

  final int? statusCode;
  final Map<String, dynamic>? meta;

  factory NetworkError.noConnection() => const NetworkError(
    message: 'No internet connection. Please check your network.',
    transportCode: 'NO_CONNECTION',
  );

  factory NetworkError.timeout() => const NetworkError(
    message: 'Request timed out. Please try again.',
    transportCode: 'TIMEOUT',
  );

  factory NetworkError.serverError({int? statusCode, String? serverMessage}) =>
      NetworkError(
        message:
            serverMessage ?? 'Server error occurred. Please try again later.',
        transportCode: 'SERVER_ERROR',
        statusCode: statusCode,
      );

  factory NetworkError.unauthorized() => const NetworkError(
    message: 'Session expired. Please login again.',
    transportCode: 'UNAUTHORIZED',
    statusCode: 401,
  );

  factory NetworkError.forbidden() => const NetworkError(
    message: 'You do not have permission to perform this action.',
    transportCode: 'FORBIDDEN',
    statusCode: 403,
  );

  factory NetworkError.notFound() => const NetworkError(
    message: 'Resource not found.',
    transportCode: 'NOT_FOUND',
    statusCode: 404,
  );

  @override
  List<Object?> get props => [...super.props, statusCode];
}

/// Database-related errors (Drift/SQLite)
final class DatabaseError extends AppError {
  const DatabaseError({
    required super.message,
    super.code,
    super.transportCode,
    super.originalError,
  });

  factory DatabaseError.notFound() => const DatabaseError(
    message: 'Record not found in local database.',
    transportCode: 'DB_NOT_FOUND',
  );

  factory DatabaseError.constraint() => const DatabaseError(
    message: 'Database constraint violation.',
    transportCode: 'DB_CONSTRAINT',
  );

  factory DatabaseError.migration() => const DatabaseError(
    message: 'Database migration failed.',
    transportCode: 'DB_MIGRATION',
  );
}

/// Authentication errors
///
/// Prefer constructing with a typed [ApiErrorCode] from the server envelope
/// rather than hard-coded factories. The legacy factories were removed in
/// the typed-error-codes migration — use the server code directly.
final class AuthError extends AppError {
  const AuthError({
    required super.message,
    super.code,
    super.transportCode,
    super.originalError,
  });
}

/// Validation errors (form validation, data validation)
final class ValidationError extends AppError {
  const ValidationError({
    required super.message,
    super.code,
    super.transportCode,
    super.originalError,
    this.field,
  });

  final String? field;

  factory ValidationError.required(String field) => ValidationError(
    message: '$field is required.',
    transportCode: 'REQUIRED',
    field: field,
  );

  factory ValidationError.invalid(String field, {String? reason}) =>
      ValidationError(
        message: reason ?? '$field is invalid.',
        transportCode: 'INVALID',
        field: field,
      );

  @override
  List<Object?> get props => [...super.props, field];
}

/// Cache/Storage errors
final class CacheError extends AppError {
  const CacheError({
    required super.message,
    super.code,
    super.transportCode,
    super.originalError,
  });

  factory CacheError.readFailed() => const CacheError(
    message: 'Failed to read from cache.',
    transportCode: 'CACHE_READ',
  );

  factory CacheError.writeFailed() => const CacheError(
    message: 'Failed to write to cache.',
    transportCode: 'CACHE_WRITE',
  );
}

/// Unknown/unexpected errors
final class UnknownError extends AppError {
  const UnknownError({
    super.message = 'An unexpected error occurred.',
    super.code,
    super.transportCode = 'UNKNOWN',
    super.originalError,
  });
}

/// Subscription required — the user attempted to access a coach-gated feature
/// without an active subscription.
///
/// Catch this specific error to show a subscription upgrade modal instead of
/// a generic error message. Do not navigate to the gated page if this is thrown.
///
/// [code] should be [ApiErrorCode.subscriptionRequired] or
/// [ApiErrorCode.subscriptionTierInsufficient] depending on the server
/// response.
final class SubscriptionRequiredError extends AppError {
  const SubscriptionRequiredError({
    super.message =
        'An active subscription is required to access this feature.',
    super.code,
    super.originalError,
  });
}
