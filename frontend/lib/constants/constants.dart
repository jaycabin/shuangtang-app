class AppConstants {
  static const String appName = '双糖';

  // 后端地址 — 你的电脑 IP: 192.168.2.15
  // 模拟器用 10.0.2.2, 真机同一 WiFi 用电脑局域网 IP
  static const String apiBaseUrl = 'http://192.168.2.15:10080/api/v1';
  static const String wsBaseUrl = 'ws://192.168.2.15:10080/ws/v1';

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String languageKey = 'language_code';
  static const String userKey = 'user_data';
  static const String coupleKey = 'couple_data';

  // Pagination
  static const int pageSize = 20;

  // Location
  static const double sugarApproachDistance = 100.0; // meters
  static const int movingInterval = 3; // seconds
  static const int stationaryInterval = 30; // seconds
}
