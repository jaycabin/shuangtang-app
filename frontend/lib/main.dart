import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'constants/theme.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/settings/language_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('settings');
  await Hive.openBox('cache');

  runApp(
    const ProviderScope(
      child: DoubleSugarApp(),
    ),
  );
}

class DoubleSugarApp extends ConsumerStatefulWidget {
  const DoubleSugarApp({super.key});

  @override
  ConsumerState<DoubleSugarApp> createState() => _DoubleSugarAppState();
}

class _DoubleSugarAppState extends ConsumerState<DoubleSugarApp> {
  Locale _locale = const Locale('zh');

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  void _loadLocale() {
    final box = Hive.box('settings');
    final langCode = box.get('language_code', defaultValue: 'zh');
    setState(() {
      _locale = Locale(langCode);
    });
  }

  void _setLocale(Locale locale) {
    final box = Hive.box('settings');
    box.put('language_code', locale.languageCode);
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '双糖',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: _locale,
      supportedLocales: const [
        Locale('zh'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale != null) {
          for (final supported in supportedLocales) {
            if (supported.languageCode == locale.languageCode) {
              return supported;
            }
          }
        }
        return const Locale('zh');
      },
      initialRoute: '/splash',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/splash':
            return MaterialPageRoute(builder: (_) => const SplashScreen());
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/home':
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          case '/settings/language':
            return MaterialPageRoute(
              builder: (_) => LanguageScreen(
                onLanguageChanged: (locale) => _setLocale(locale),
              ),
            );
          default:
            return MaterialPageRoute(builder: (_) => const SplashScreen());
        }
      },
    );
  }
}
