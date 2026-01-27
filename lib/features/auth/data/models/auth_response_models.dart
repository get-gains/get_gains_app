import 'package:freezed_annotation/freezed_annotation.dart';

import 'user_model.dart';

part 'auth_response_models.freezed.dart';
part 'auth_response_models.g.dart';

/// Auth Response Model (Full User)
///
/// Returned from register and login endpoints.
/// Contains JWT tokens and complete user data.
@freezed
abstract class AuthResponse with _$AuthResponse {
  const factory AuthResponse({
    required String accessToken,
    required String refreshToken,
    required UserModel user,
  }) = _AuthResponse;

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
}

/// Extension for AuthResponse custom factories
extension AuthResponseX on AuthResponse {
  /// Create from API response which wraps data in 'data' field
  static AuthResponse fromApiResponse(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return AuthResponse(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
    );
  }
}

/// Google Sign-In Response Model (Partial User)
///
/// Returned from initial Google sign-in (/auth/google).
/// Contains tokens but only partial user data (email, supabaseId).
/// Full profile must be created via /auth/google/link endpoint.
@freezed
abstract class GoogleSignInResponse with _$GoogleSignInResponse {
  const factory GoogleSignInResponse({
    required String accessToken,
    required String refreshToken,
    required PartialUserModel user,
  }) = _GoogleSignInResponse;

  factory GoogleSignInResponse.fromJson(Map<String, dynamic> json) =>
      _$GoogleSignInResponseFromJson(json);
}

/// Extension for GoogleSignInResponse custom factories
extension GoogleSignInResponseX on GoogleSignInResponse {
  /// Create from API response which wraps data in 'data' field
  static GoogleSignInResponse fromApiResponse(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return GoogleSignInResponse(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      user: PartialUserModel.fromJson(data['user'] as Map<String, dynamic>),
    );
  }
}

/// Token Refresh Response Model
///
/// Returned from token refresh endpoint.
@freezed
abstract class TokenRefreshResponse with _$TokenRefreshResponse {
  const factory TokenRefreshResponse({
    required String accessToken,
    required String refreshToken,
  }) = _TokenRefreshResponse;

  factory TokenRefreshResponse.fromJson(Map<String, dynamic> json) =>
      _$TokenRefreshResponseFromJson(json);
}

/// Extension for TokenRefreshResponse custom factories
extension TokenRefreshResponseX on TokenRefreshResponse {
  /// Create from API response which wraps data in 'data' field
  static TokenRefreshResponse fromApiResponse(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return TokenRefreshResponse(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
  }
}

/// API Error Response Model
///
/// Represents error responses from the API.
/// All API errors follow this structure: { data: null, errors: [...] }
@freezed
abstract class ApiErrorResponse with _$ApiErrorResponse {
  const factory ApiErrorResponse({required List<ApiError> errors}) =
      _ApiErrorResponse;

  factory ApiErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorResponseFromJson(json);
}

/// Individual API Error
@freezed
abstract class ApiError with _$ApiError {
  const factory ApiError({required String message, String? field}) = _ApiError;

  factory ApiError.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorFromJson(json);
}
