import 'package:flutter/material.dart';

// ========== 色彩体系 ==========
class AppColors {
  // 主色
  static const peach = Color(0xFFFF9A9E);
  static const warmOrange = Color(0xFFFECF86);
  static const brandGradient = LinearGradient(
    colors: [peach, warmOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const brandGradientVertical = LinearGradient(
    colors: [peach, warmOrange],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // 辅助色
  static const frostingWhite = Color(0xFFFFF5F5);
  static const sugarCoatPink = Color(0xFFFFE0E0);
  static const caramel = Color(0xFFC49B7A);
  static const creamWhite = Color(0xFFFAFAFA);

  // 语义色
  static const successGreen = Color(0xFF7ECB9A);
  static const alertRed = Color(0xFFFF6B6B);
  static const linkBlue = Color(0xFF7B9ED0);
  static const darkText = Color(0xFF3D2C2C);
  static const greyText = Color(0xFFB8A8A8);

  // 暗色
  static const darkBg = Color(0xFF1A1515);
  static const darkCard = Color(0xFF2D2424);
  static const darkTextLight = Color(0xFFF0E0D6);
}

// ========== 圆角 ==========
class AppRadius {
  static const double card = 24.0;
  static const double button = 16.0;
  static const double input = 12.0;
  static const double dialog = 28.0;
  static const double image = 16.0;
  static const double tag = 8.0;
}

// ========== 阴影 ==========
class AppShadows {
  static List<BoxShadow> get card => [
    BoxShadow(
      color: const Color(0x1AFF9A9E),
      offset: const Offset(0, 4),
      blurRadius: 12,
    ),
  ];

  static List<BoxShadow> get button => [
    BoxShadow(
      color: const Color(0x33FF9A9E),
      offset: const Offset(0, 4),
      blurRadius: 12,
    ),
  ];

  static List<BoxShadow> get dialog => [
    BoxShadow(
      color: const Color(0x33FF9A9E),
      offset: const Offset(0, 8),
      blurRadius: 24,
    ),
  ];
}

// ========== 间距 ==========
class AppSpacing {
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;

  // 页面左右边距
  static const EdgeInsets pageHorizontal = EdgeInsets.symmetric(horizontal: lg);
  // 卡片内边距
  static const EdgeInsets cardPadding = EdgeInsets.all(20.0);
}

// ========== 动效 ==========
class AppDurations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration toast = Duration(milliseconds: 800);
}

// ========== 文字样式 ==========
class AppTextStyles {
  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.darkText,
  );
  static const TextStyle h2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.darkText,
  );
  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.darkText,
  );
  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: AppColors.darkText,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.greyText,
  );
}

// ========== Flutter Theme ==========
class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.creamWhite,
    fontFamily: 'PingFang SC',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: AppColors.darkText,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.darkText,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.frostingWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.peach, width: 1.5),
      ),
      hintStyle: const TextStyle(color: AppColors.greyText, fontSize: 15),
      labelStyle: const TextStyle(color: AppColors.caramel, fontSize: 14),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.frostingWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.peach,
      primary: AppColors.peach,
      secondary: AppColors.warmOrange,
      surface: AppColors.frostingWhite,
      brightness: Brightness.light,
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.peach,
      secondary: AppColors.warmOrange,
      surface: AppColors.darkCard,
    ),
  );
}
