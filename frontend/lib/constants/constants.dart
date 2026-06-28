class AppConstants {
  static const String appName = '双糖';

  // ======== Supabase 配置 ========
  // 在 app.supabase.com 创建项目后，Settings → API 里找到这两项
  static const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
  static const String supabaseAnonKey = 'YOUR_ANON_KEY';

  // Storage keys
  static const String tokenKey = 'supabase_token';
  static const String languageKey = 'language_code';
  static const String userKey = 'user_data';
  static const String coupleKey = 'couple_data';

  // Location
  static const double sugarApproachDistance = 100.0; // meters
  static const int movingInterval = 3; // seconds
  static const int stationaryInterval = 30; // seconds
}
