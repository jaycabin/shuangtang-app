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
  String _selected = 'zh';

  final _langs = [
    {'code': 'zh', 'name': '简体中文', 'nameEn': 'Chinese', 'flag': '🇨🇳'},
    {'code': 'en', 'name': 'English', 'nameEn': 'English', 'flag': '🇺🇸'},
  ];

  @override
  void initState() {
    super.initState();
    _selected = Hive.box('settings').get('language_code', defaultValue: 'zh');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('语言 / Language')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _langs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final lang = _langs[i];
          final s = _selected == lang['code'];
          return GestureDetector(
            onTap: () {
              setState(() => _selected = lang['code']!);
              widget.onLanguageChanged(Locale(lang['code']!));
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.frostingWhite,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: s ? Border.all(color: AppColors.peach, width: 2) : null,
                boxShadow: s ? AppShadows.card : null,
              ),
              child: Row(children: [
                Text(lang['flag']!, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(lang['name']!, style: AppTextStyles.body),
                    Text(lang['nameEn']!, style: AppTextStyles.caption),
                  ]),
                ),
                if (s) const Icon(Icons.check_circle, color: AppColors.peach, size: 24),
              ]),
            ),
          );
        },
      ),
    );
  }
}
