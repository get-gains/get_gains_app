import 'package:freezed_annotation/freezed_annotation.dart';

import '../errors/api_error_codes.dart';

part 'api_response.freezed.dart';
part 'api_response.g.dart';

/// Standard API Error structure
///
/// Matches the server's `ApiError` format:
/// ```json
/// { "field": "email", "code": "AUTH_INVALID_CREDENTIALS", "message": "Invalid email or password." }
/// ```
@freezed
abstract class ApiError with _$ApiError {
  const factory ApiError({
    String? field,
    String? code,
    required String message,
  }) = _ApiError;

  factory ApiError.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorFromJson(json);
}

/// Standard API Response structure
///
/// All server responses follow this format:
/// ```json
/// {
///   "data": { ... } | null,
///   "errors": []
/// }
/// ```
///
/// On success:
/// - `data` contains the response payload
/// - `errors` is an empty array
///
/// On error:
/// - `data` is null
/// - `errors` contains one or more `ApiError` objects
@freezed
abstract class ApiResponse<T> with _$ApiResponse<T> {
  const factory ApiResponse({
    required T? data,
    required List<ApiError> errors,
  }) = _ApiResponse<T>;
}

/// Extension to parse raw API response
extension ApiResponseParser on Map<String, dynamic> {
  /// Parse raw JSON into ApiResponse
  ///
  /// Returns the unwrapped data if successful, otherwise throws with error info.
  /// This is typically called by ApiClient internally.
  ApiResponse<Map<String, dynamic>> toApiResponse() {
    final errors =
        (this['errors'] as List<dynamic>?)
            ?.map((e) => ApiError.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return ApiResponse(
      data: this['data'] as Map<String, dynamic>?,
      errors: errors,
    );
  }

  /// Check if this response indicates success (no errors)
  bool get isSuccessResponse =>
      containsKey('errors') && (this['errors'] as List).isEmpty;

  /// Check if this response indicates failure (has errors)
  bool get isErrorResponse =>
      containsKey('errors') && (this['errors'] as List).isNotEmpty;

  /// Get the first error message, if any
  String? get firstErrorMessage {
    final errors = this['errors'] as List<dynamic>?;
    if (errors == null || errors.isEmpty) return null;
    final first = errors.first as Map<String, dynamic>;
    return first['message'] as String?;
  }

  /// Get the first error's typed [ApiErrorCode], if present.
  ///
  /// Returns `null` when the server did not include a `code` field (legacy
  /// responses). Returns [ApiErrorCode.unknown] when the code string is
  /// present but not recognized by the generated enum.
  ApiErrorCode? get firstErrorCode {
    final errors = this['errors'] as List<dynamic>?;
    if (errors == null || errors.isEmpty) return null;
    final first = errors.first as Map<String, dynamic>;
    final raw = first['code'] as String?;
    if (raw == null || raw.isEmpty) return null;
    return ApiErrorCode.fromString(raw);
  }

  /// Get all error messages joined
  String get allErrorMessages {
    final errors = this['errors'] as List<dynamic>?;
    if (errors == null || errors.isEmpty) return 'Unknown error';
    return errors
        .map((e) => (e as Map<String, dynamic>)['message'] as String?)
        .whereType<String>()
        .join(', ');
  }
}
