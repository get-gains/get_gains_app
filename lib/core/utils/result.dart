import 'package:equatable/equatable.dart';

/// Result Type for Error Handling
///
/// A functional approach to error handling that avoids exceptions.
/// Use instead of try-catch for predictable error flows.
///
/// Usage:
/// ```dart
/// Result<User, AppError> result = await authRepository.login(email, password);
/// result.when(
///   success: (user) => navigateToHome(),
///   failure: (error) => showError(error.message),
/// );
/// ```
sealed class Result<T, E> extends Equatable {
  const Result();

  /// Returns true if the result is a success
  bool get isSuccess => this is Success<T, E>;

  /// Returns true if the result is a failure
  bool get isFailure => this is Failure<T, E>;

  /// Gets the success value or null
  T? get valueOrNull => switch (this) {
    Success<T, E>(:final value) => value,
    Failure<T, E>() => null,
  };

  /// Gets the error or null
  E? get errorOrNull => switch (this) {
    Success<T, E>() => null,
    Failure<T, E>(:final error) => error,
  };

  /// Gets the value or throws
  T get valueOrThrow => switch (this) {
    Success<T, E>(:final value) => value,
    Failure<T, E>(:final error) => throw Exception(error),
  };

  /// Pattern matching on result
  R when<R>({
    required R Function(T value) success,
    required R Function(E error) failure,
  }) {
    return switch (this) {
      Success<T, E>(:final value) => success(value),
      Failure<T, E>(:final error) => failure(error),
    };
  }

  /// Map success value
  Result<R, E> map<R>(R Function(T value) mapper) {
    return switch (this) {
      Success<T, E>(:final value) => Success(mapper(value)),
      Failure<T, E>(:final error) => Failure(error),
    };
  }

  /// Map error value
  Result<T, R> mapError<R>(R Function(E error) mapper) {
    return switch (this) {
      Success<T, E>(:final value) => Success(value),
      Failure<T, E>(:final error) => Failure(mapper(error)),
    };
  }

  /// FlatMap for chaining results
  Result<R, E> flatMap<R>(Result<R, E> Function(T value) mapper) {
    return switch (this) {
      Success<T, E>(:final value) => mapper(value),
      Failure<T, E>(:final error) => Failure(error),
    };
  }
}

/// Success case of Result
final class Success<T, E> extends Result<T, E> {
  const Success(this.value);
  final T value;

  @override
  List<Object?> get props => [value];
}

/// Failure case of Result
final class Failure<T, E> extends Result<T, E> {
  const Failure(this.error);
  final E error;

  @override
  List<Object?> get props => [error];
}
