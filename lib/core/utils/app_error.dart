import 'package:equatable/equatable.dart';

/// Application Error Types
///
/// Centralized error handling with typed errors for different failure scenarios.
/// Use with `Result<T, AppError>` for consistent error handling across the app.
sealed class AppError extends Equatable {
  const AppError({required this.message, this.code, this.originalError});

  final String message;
  final String? code;
  final Object? originalError;

  @override
  List<Object?> get props => [message, code, originalError];
}

/// Network-related errors (API calls, connectivity)
final class NetworkError extends AppError {
  const NetworkError({
    required super.message,
    super.code,
    super.originalError,
    this.statusCode,
  });

  final int? statusCode;

  factory NetworkError.noConnection() => const NetworkError(
    message: 'No internet connection. Please check your network.',
    code: 'NO_CONNECTION',
  );

  factory NetworkError.timeout() => const NetworkError(
    message: 'Request timed out. Please try again.',
    code: 'TIMEOUT',
  );

  factory NetworkError.serverError({int? statusCode, String? serverMessage}) =>
      NetworkError(
        message:
            serverMessage ?? 'Server error occurred. Please try again later.',
        code: 'SERVER_ERROR',
        statusCode: statusCode,
      );

  factory NetworkError.unauthorized() => const NetworkError(
    message: 'Session expired. Please login again.',
    code: 'UNAUTHORIZED',
    statusCode: 401,
  );

  factory NetworkError.forbidden() => const NetworkError(
    message: 'You do not have permission to perform this action.',
    code: 'FORBIDDEN',
    statusCode: 403,
  );

  factory NetworkError.notFound() => const NetworkError(
    message: 'Resource not found.',
    code: 'NOT_FOUND',
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
    super.originalError,
  });

  factory DatabaseError.notFound() => const DatabaseError(
    message: 'Record not found in local database.',
    code: 'DB_NOT_FOUND',
  );

  factory DatabaseError.constraint() => const DatabaseError(
    message: 'Database constraint violation.',
    code: 'DB_CONSTRAINT',
  );

  factory DatabaseError.migration() => const DatabaseError(
    message: 'Database migration failed.',
    code: 'DB_MIGRATION',
  );
}

/// Authentication errors
final class AuthError extends AppError {
  const AuthError({required super.message, super.code, super.originalError});

  factory AuthError.invalidCredentials() => const AuthError(
    message: 'Invalid email or password.',
    code: 'INVALID_CREDENTIALS',
  );

  factory AuthError.tokenExpired() => const AuthError(
    message: 'Your session has expired. Please login again.',
    code: 'TOKEN_EXPIRED',
  );

  factory AuthError.tokenRefreshFailed() => const AuthError(
    message: 'Failed to refresh session. Please login again.',
    code: 'TOKEN_REFRESH_FAILED',
  );

  factory AuthError.accountLocked() => const AuthError(
    message: 'Account locked. Please contact support.',
    code: 'ACCOUNT_LOCKED',
  );
}

/// Validation errors (form validation, data validation)
final class ValidationError extends AppError {
  const ValidationError({
    required super.message,
    super.code,
    super.originalError,
    this.field,
  });

  final String? field;

  factory ValidationError.required(String field) => ValidationError(
    message: '$field is required.',
    code: 'REQUIRED',
    field: field,
  );

  factory ValidationError.invalid(String field, {String? reason}) =>
      ValidationError(
        message: reason ?? '$field is invalid.',
        code: 'INVALID',
        field: field,
      );

  @override
  List<Object?> get props => [...super.props, field];
}

/// Cache/Storage errors
final class CacheError extends AppError {
  const CacheError({required super.message, super.code, super.originalError});

  factory CacheError.readFailed() => const CacheError(
    message: 'Failed to read from cache.',
    code: 'CACHE_READ',
  );

  factory CacheError.writeFailed() => const CacheError(
    message: 'Failed to write to cache.',
    code: 'CACHE_WRITE',
  );
}

/// Unknown/unexpected errors
final class UnknownError extends AppError {
  const UnknownError({
    super.message = 'An unexpected error occurred.',
    super.code = 'UNKNOWN',
    super.originalError,
  });
}
