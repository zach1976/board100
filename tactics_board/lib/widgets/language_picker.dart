import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class LanguagePicker {
  static const _languages = [
    (locale: Locale('en', 'US'), name: 'English'),
    (locale: Locale('zh', 'CN'), name: '简体中文'),
    (locale: Locale('zh', 'TW'), name: '繁體中文'),
    (locale: Locale('ja', 'JP'), name: '日本語'),
    (locale: Locale('ko', 'KR'), name: '한국어'),
    (locale: Locale('fr', 'FR'), name: 'Français'),
    (locale: Locale('es', 'ES'), name: 'Español'),
    (locale: Locale('vi', 'VN'), name: 'Tiếng Việt'),
    (locale: Locale('th', 'TH'), name: 'ภาษาไทย'),
    (locale: Locale('id', 'ID'), name: 'Bahasa Indonesia'),
    (locale: Locale('ms', 'MY'), name: 'Bahasa Melayu'),
  ];

  static void show(BuildContext context) {
    final current = context.locale;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2035),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Language / 语言',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ..._languages.map((lang) {
                      final selected = current == lang.locale;
                      return ListTile(
                        title: Text(
                          lang.name,
                          style: TextStyle(
                            color: selected ? Colors.blue : Colors.white,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 16,
                          ),
                        ),
                        trailing: selected
                            ? const Icon(Icons.check, color: Colors.blue, size: 20)
                            : null,
                        selectedTileColor: Colors.blue.withValues(alpha: 0.08),
                        selected: selected,
                        onTap: () {
                          Navigator.pop(ctx);
                          // Use the outer context (with EasyLocalization) to set locale
                          Future.microtask(() => context.setLocale(lang.locale));
                        },
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
