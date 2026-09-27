class AppConstants {
  static const String baseUrl = 'http://10.158.76.252:8080/api/v1'; // For Android emulator. Use your actual IP or localhost if web.
  static const String googleClientId = '235362183473-9sl8c2n5tiv2ipoit4ih3dlcogc02anj.apps.googleusercontent.com'; // Replace this
  
  // WebSocket URL derived from baseUrl (replace http with ws)
  static String get wsUrl {
    return baseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
  }
}
