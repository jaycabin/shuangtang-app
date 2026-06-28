import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'constants/theme.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/settings/language_screen.dart';
import 'generated/l10n/app_localizations.dart';
import 'services/offline_queue.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('settings');
  await Hive.openBox('cache');
  await Hive.openBox('offline_queue');

  // 初始化离线队列
  await OfflineQueue().init();

  runApp(const DoubleSugarApp());
}

class DoubleSugarApp extends StatefulWidget {
  const DoubleSugarApp({super.key});

  @override
  State<DoubleSugarApp> createState() => _DoubleSugarAppState();
}

class _DoubleSugarAppState extends State<DoubleSugarApp> {
  Locale _locale = const Locale('zh');

  @override
  void initState() {
    super.initState();
    final box = Hive.box('settings');
    final lang = box.get('language_code', defaultValue: 'zh');
    _locale = Locale(lang);
  }

  void _setLocale(Locale l) {
    Hive.box('settings').put('language_code', l.languageCode);
    setState(() => _locale = l);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '双糖',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: _locale,
      supportedLocales: const [Locale('zh'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (l, s) {
        if (l != null) for (final x in s) { if (x.languageCode == l.languageCode) return x; }
        return const Locale('zh');
      },
      initialRoute: '/splash',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/splash': return MaterialPageRoute(builder: (_) => const SplashScreen());
          case '/login': return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/home': return MaterialPageRoute(builder: (_) => const HomeScreen());
          case '/settings/language':
            return MaterialPageRoute(builder: (_) => LanguageScreen(onLanguageChanged: _setLocale));
          default: return MaterialPageRoute(builder: (_) => const SplashScreen());
        }
      },
    );
  }
}
