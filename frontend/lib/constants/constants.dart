class AppConstants {
  static const String appName = '双糖';

  // 你的后端地址 — 开发用 10.0.2.2（Android 模拟器映射宿主机 localhost）
  // 真机测试改成你电脑的局域网 IP
  // 生产部署改成服务器域名/IP
  static const String apiBaseUrl = 'http://10.0.2.2:10080/api/v1';
  static const String wsBaseUrl = 'ws://10.0.2.2:10080/ws/v1';

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
