import 'package:freezed_annotation/freezed_annotation.dart';

import 'user_model.dart';

part 'auth_response_models.freezed.dart';
part 'auth_response_models.g.dart';

/// Result of a Google login attempt.
///
/// When the user taps "Sign in with Google" from the login screen:
/// - [existingUser]: Login succeeded, user already has a profile.
/// - [newUser]: User authenticated with Google but has no profile yet.
///   The app should navigate to the profile completion screen.
sealed class GoogleLoginResult {
  const GoogleLoginResult._();

  const factory GoogleLoginResult.existingUser(AuthResponse response) =
      GoogleLoginExistingUser;

  const factory GoogleLoginResult.newUser(
    GoogleSignInResponse response, {
    String? suggestedName,
  }) = GoogleLoginNewUser;
}

class GoogleLoginExistingUser extends GoogleLoginResult {
  const GoogleLoginExistingUser(this.response) : super._();
  final AuthResponse response;
}

class GoogleLoginNewUser extends GoogleLoginResult {
  const GoogleLoginNewUser(this.response, {this.suggestedName}) : super._();
  final GoogleSignInResponse response;
  final String? suggestedName;
}

/// Auth Response Model (Full User)
///
/// Returned from login endpoints.
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
  /// Create from raw API response data
  ///
  /// Note: ApiClient now automatically unwraps { data, errors } format,
  /// so you typically just need `fromJson` on the already-unwrapped data.
  /// This method is kept for backwards compatibility.
  @Deprecated('Use AuthResponse.fromJson on unwrapped data instead')
  static AuthResponse fromApiResponse(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return AuthResponse(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
    );
  }
}

/// Register Response Model
///
/// Returned from register endpoint.
/// Does NOT contain tokens because email verification is required.
/// User must verify email before logging in.
@freezed
abstract class RegisterResponse with _$RegisterResponse {
  const factory RegisterResponse({required UserModel user}) = _RegisterResponse;

  factory RegisterResponse.fromJson(Map<String, dynamic> json) =>
      _$RegisterResponseFromJson(json);
}

/// Extension for RegisterResponse custom factories
extension RegisterResponseX on RegisterResponse {
  /// Create from raw API response data
  ///
  /// Note: ApiClient now automatically unwraps { data, errors } format,
  /// so you typically just need `fromJson` on the already-unwrapped data.
  /// This method is kept for backwards compatibility.
  @Deprecated('Use RegisterResponse.fromJson on unwrapped data instead')
  static RegisterResponse fromApiResponse(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return RegisterResponse(
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
  /// Create from raw API response data
  ///
  /// Note: ApiClient now automatically unwraps { data, errors } format,
  /// so you typically just need `fromJson` on the already-unwrapped data.
  /// This method is kept for backwards compatibility.
  @Deprecated('Use GoogleSignInResponse.fromJson on unwrapped data instead')
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
  /// Create from raw API response data
  ///
  /// Note: ApiClient now automatically unwraps { data, errors } format,
  /// so you typically just need `fromJson` on the already-unwrapped data.
  /// This method is kept for backwards compatibility.
  @Deprecated('Use TokenRefreshResponse.fromJson on unwrapped data instead')
  static TokenRefreshResponse fromApiResponse(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return TokenRefreshResponse(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
  }
}

// Note: ApiError and ApiErrorResponse are now defined in
// lib/core/utils/api_response.dart for app-wide use.
// Import from there: import '../../../../core/utils/api_response.dart';
