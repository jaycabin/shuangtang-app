import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../constants/theme.dart';

class LanguageScreen extends StatefulWidget {
  final Function(Locale) onLanguageChanged;

  const LanguageScreen({super.key, required this.onLanguageChanged});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  late String _selectedLanguage;
  final _languages = [
    {'code': 'zh', 'name': '中文', 'native': '简体中文', 'flag': '🇨🇳'},
    {'code': 'en', 'name': 'English', 'native': 'English', 'flag': '🇺🇸'},
  ];

  @override
  void initState() {
    super.initState();
    final box = Hive.box('settings');
    _selectedLanguage = box.get('language_code', defaultValue: 'zh');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('语言 / Language'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _languages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final lang = _languages[index];
          final isSelected = _selectedLanguage == lang['code'];

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: isSelected ? AppTheme.primaryStart : Colors.transparent,
                width: isSelected ? 2 : 0,
              ),
              boxShadow: isSelected ? AppTheme.cardShadow : null,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Text(
                lang['flag']!,
                style: const TextStyle(fontSize: 32),
              ),
              title: Text(
                lang['name']!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                lang['native']!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: AppTheme.primaryStart)
                  : null,
              onTap: () {
                setState(() => _selectedLanguage = lang['code']!);
                final locale = Locale(lang['code']!);
                widget.onLanguageChanged(locale);
                Navigator.pop(context);
              },
            ),
          );
        },
      ),
    );
  }
}
