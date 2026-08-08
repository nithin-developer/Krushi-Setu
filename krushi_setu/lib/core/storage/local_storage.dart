import 'package:hive_flutter/hive_flutter.dart';

class LocalStorage {
  static const String _boxName = 'app_preferences';
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _languageKey = 'preferred_language';

  static late Box _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  static Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _box.put(_accessTokenKey, accessToken);
    await _box.put(_refreshTokenKey, refreshToken);
  }

  static String? get accessToken => _box.get(_accessTokenKey);
  static String? get refreshToken => _box.get(_refreshTokenKey);

  static Future<void> clearTokens() async {
    await _box.delete(_accessTokenKey);
    await _box.delete(_refreshTokenKey);
  }

  static Future<void> saveLanguage(String languageCode) async {
    await _box.put(_languageKey, languageCode);
  }

  static String get language => _box.get(_languageKey, defaultValue: 'en');
}
