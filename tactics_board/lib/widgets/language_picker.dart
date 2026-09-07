import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../ui/primitives.dart';
import '../ui/tokens.dart';
import 'toolbar.dart' show scaledSheet;

class LanguagePicker {
  static const _languages = [
    (locale: Locale('en', 'US'), name: 'English (US)'),
    (locale: Locale('en', 'GB'), name: 'English (UK)'),
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
    TacticalSheet.show(
      context,
      builder: (ctx) => scaledSheet(
        ctx,
        TacticalSheet(
          maxHeightFraction: 0.78,
          padding: const EdgeInsets.fromLTRB(T.s12, T.s12, T.s12, T.s8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: T.s12),
                child: TacticalSheetHeader(title: 'Language / 语言'),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _languages.length,
                  itemBuilder: (_, i) {
                    final lang = _languages[i];
                    final selected = current == lang.locale;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Material(
                        // Teal, like every other selection in the app. This
                        // row used to be the one place that went bright blue.
                        color: selected ? T.accentFill : Colors.transparent,
                        borderRadius: T.brSm,
                        child: InkWell(
                          borderRadius: T.brSm,
                          onTap: () {
                            Navigator.pop(ctx);
                            Future.microtask(
                                () => context.setLocale(lang.locale));
                          },
                          child: Container(
                            height: 56,
                            padding:
                                const EdgeInsets.symmetric(horizontal: T.s12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    lang.name,
                                    style: TextStyle(
                                      color: selected ? T.accent : T.text,
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                // Selection is a tint AND a mark, never
                                // colour alone.
                                if (selected)
                                  const Icon(Icons.check_rounded,
                                      color: T.accent, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
