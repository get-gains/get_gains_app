import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// Server responses use Prisma snake_case (`supabase_auth_id`, `full_name`);
/// cached / client JSON uses camelCase (`supabaseId`, `name`, `id`).
Map<String, dynamic> _normalizeUserModelJson(Map<String, dynamic> json) {
  final out = Map<String, dynamic>.from(json);
  final supabaseId = out['supabaseId'] ?? out['supabase_auth_id'];
  out['id'] = out['id'] ?? supabaseId;
  out['name'] = out['name'] ?? out['full_name'];
  out['supabaseId'] = supabaseId;
  return out;
}

/// User Model
///
/// Represents a user in the Get Gains application.
/// Used for both API responses and local storage.
@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String email,
    required String name,
    required String nickname,
    required String supabaseId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(_normalizeUserModelJson(json));
}

/// Partial user data returned from Google sign-in (before profile completion)
@freezed
abstract class PartialUserModel with _$PartialUserModel {
  const factory PartialUserModel({
    required String email,
    required String supabaseId,
  }) = _PartialUserModel;

  factory PartialUserModel.fromJson(Map<String, dynamic> json) =>
      _$PartialUserModelFromJson({
        'email': json['email'],
        'supabaseId': json['supabaseId'] ?? json['supabase_auth_id'],
      });
}
