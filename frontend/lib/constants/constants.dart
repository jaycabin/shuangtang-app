class AppConstants {
  static const String appName = '双糖';
  static const String apiBaseUrl = 'http://10.0.2.2:10080/api/v1';
  static const String wsBaseUrl = 'ws://10.0.2.2:10080/ws/v1';

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String languageKey = 'language_code';
  static const String userKey = 'user_data';
  static const String coupleKey = 'couple_data';
  static const String themeKey = 'theme_mode';

  // Pagination
  static const int pageSize = 20;

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Location
  static const double sugarApproachDistance = 100.0; // meters
  static const int movingInterval = 3; // seconds
  static const int stationaryInterval = 30; // seconds
}
