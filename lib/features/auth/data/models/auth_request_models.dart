import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_request_models.freezed.dart';
part 'auth_request_models.g.dart';

/// Register Request Model (Email/Password)
///
/// Used to register a new user with email and password.
/// Matches server's RegisterSchema validation.
@freezed
abstract class RegisterRequest with _$RegisterRequest {
  const factory RegisterRequest({
    required String email,
    required String password,
    required String name,
    required String nickname,
  }) = _RegisterRequest;

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);
}

/// Google Sign-In Request Model
///
/// Used to sign in with Google OAuth.
/// Sends Google ID token to server for verification.
@freezed
abstract class GoogleSignInRequest with _$GoogleSignInRequest {
  const factory GoogleSignInRequest({required String idToken}) =
      _GoogleSignInRequest;

  factory GoogleSignInRequest.fromJson(Map<String, dynamic> json) =>
      _$GoogleSignInRequestFromJson(json);
}

/// Create User from Google Request Model
///
/// Used to complete Google sign-up by creating user profile.
/// Called after initial Google sign-in to add name/nickname.
@freezed
abstract class CreateUserFromGoogleRequest with _$CreateUserFromGoogleRequest {
  const factory CreateUserFromGoogleRequest({
    required String email,
    required String name,
    required String nickname,
    required String supabaseId,
  }) = _CreateUserFromGoogleRequest;

  factory CreateUserFromGoogleRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateUserFromGoogleRequestFromJson(json);
}

/// Send Recovery Email Request Model
///
/// Used to request password recovery email.
@freezed
abstract class SendRecoveryEmailRequest with _$SendRecoveryEmailRequest {
  const factory SendRecoveryEmailRequest({required String email}) =
      _SendRecoveryEmailRequest;

  factory SendRecoveryEmailRequest.fromJson(Map<String, dynamic> json) =>
      _$SendRecoveryEmailRequestFromJson(json);
}

/// Reset Password Request Model
///
/// Used to reset password with recovery token.
/// Note: This is an authenticated endpoint (uses access token from email link).
@freezed
abstract class ResetPasswordRequest with _$ResetPasswordRequest {
  const factory ResetPasswordRequest({
    required String accessToken,
    required String newPassword,
  }) = _ResetPasswordRequest;

  factory ResetPasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ResetPasswordRequestFromJson(json);
}
