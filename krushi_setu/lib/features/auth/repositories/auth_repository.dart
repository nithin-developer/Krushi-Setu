import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:krushi_setu/features/auth/models/user_model.dart';
import 'package:krushi_setu/core/network/dio_client.dart';
import 'package:krushi_setu/core/storage/local_storage.dart';
import 'package:krushi_setu/core/constants/app_constants.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthRepository {
  final DioClient _dioClient;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    clientId: AppConstants.googleClientId,
  );

  AuthRepository(this._dioClient);

  Exception _handleError(dynamic e) {
    if (e is DioException) {
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data.containsKey('detail')) {
          final detail = data['detail'];
          if (detail is String) {
            return AuthException(detail);
          } else if (detail is List && detail.isNotEmpty) {
            return AuthException(detail[0]['msg']?.toString() ?? 'Validation Error');
          }
        }
      }
      return AuthException(e.message ?? 'Network error occurred');
    }
    return Exception(e.toString());
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    try {
      final response = await _dioClient.dio.post('/auth/register', data: {
        'full_name': fullName,
        'email': email,
        'password': password,
        if (phoneNumber != null) 'phone_number': phoneNumber,
      });
      
      await LocalStorage.saveTokens(
        response.data['access_token'],
        response.data['refresh_token'],
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final response = await _dioClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      await LocalStorage.saveTokens(
        response.data['access_token'],
        response.data['refresh_token'],
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception("Google sign in aborted");
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      
      if (idToken == null) {
        throw Exception("Google ID token not found");
      }
      
      final response = await _dioClient.dio.post('/auth/google-login', data: {
        'id_token': idToken,
      });
      
      await LocalStorage.saveTokens(
        response.data['access_token'],
        response.data['refresh_token'],
      );
    } catch (e) {
      await _googleSignIn.signOut();
      throw _handleError(e);
    }
  }

  Future<UserModel> getCurrentUser() async {
    final response = await _dioClient.dio.get('/auth/me');
    return UserModel.fromJson(response.data);
  }

  Future<void> logout() async {
    await LocalStorage.clearTokens();
    await _googleSignIn.signOut();
  }
}
