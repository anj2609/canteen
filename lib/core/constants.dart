class AppConstants {
  // DEVELOPMENT MODE: Set to true when testing locally
  // PRODUCTION MODE: Set to false before building release APK
  static const bool isDevelopment = false; // Using production API

  // Development URLs (for local backend testing)
  // Use 10.0.2.2 for Android Emulator to access localhost of the host machine
  static const String devBaseUrlAndroid = 'http://10.0.2.2:3000/api/v1';
  static const String devBaseUrlIOS = 'http://localhost:3000/api/v1';
  // For physical device, use your computer's local IP:
  // static const String devBaseUrlPhysical = 'http://192.168.1.100:3000/api/v1';

  // Production URL
  static const String prodBaseUrl = 'https://api.dranjali.tech/api/v1';

  // Auto-select based on mode
  static String get baseUrl {
    if (isDevelopment) {
      return devBaseUrlAndroid; // Change to devBaseUrlIOS for iOS simulator
    }
    return prodBaseUrl;
  }

  static const String authTokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
}
