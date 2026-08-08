// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['id'] as String,
  fullName: json['full_name'] as String,
  email: json['email'] as String,
  phoneNumber: json['phone_number'] as String?,
  provider: json['provider'] as String,
  googleId: json['google_id'] as String?,
  profileImage: json['profile_image'] as String?,
  preferredLanguage: json['preferred_language'] as String,
  profileCompleted: json['profile_completed'] as bool,
  status: json['status'] as String,
  lastLogin: json['last_login'] == null
      ? null
      : DateTime.parse(json['last_login'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'full_name': instance.fullName,
  'email': instance.email,
  'phone_number': instance.phoneNumber,
  'provider': instance.provider,
  'google_id': instance.googleId,
  'profile_image': instance.profileImage,
  'preferred_language': instance.preferredLanguage,
  'profile_completed': instance.profileCompleted,
  'status': instance.status,
  'last_login': instance.lastLogin?.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
