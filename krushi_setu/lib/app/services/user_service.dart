import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:krushi_setu/core/constants/app_constants.dart';
import 'package:krushi_setu/core/storage/local_storage.dart';
import 'package:krushi_setu/app/models/user_model.dart';

class UserService {
  Future<UserModel?> fetchMyProfile() async {
    final token = LocalStorage.accessToken;
    if (token == null || token.isEmpty) return null;

    final uri = Uri.parse('${AppConstants.baseUrl}/profile/me');
    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  Future<UserModel?> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? preferredLanguage,
  }) async {
    final token = LocalStorage.accessToken;
    if (token == null || token.isEmpty) return null;

    final uri = Uri.parse('${AppConstants.baseUrl}/profile/me');
    final body = <String, dynamic>{};
    if (fullName != null) body['full_name'] = fullName;
    if (phoneNumber != null) body['phone_number'] = phoneNumber;
    if (preferredLanguage != null) body['preferred_language'] = preferredLanguage;

    try {
      final response = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> fetchDigitalTwin() async {
    final token = LocalStorage.accessToken;
    if (token == null || token.isEmpty) return null;

    final uri = Uri.parse('${AppConstants.baseUrl}/profile/digital-twin');
    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }
}
