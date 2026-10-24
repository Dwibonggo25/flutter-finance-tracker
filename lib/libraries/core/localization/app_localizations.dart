import 'package:flutter/material.dart';

import 'languages/en.dart';
import 'languages/in.dart';

class AppLocalizations {
  final Locale locale;

  const AppLocalizations(this.locale);

  static const supportedLocales = [Locale('id'), Locale('en')];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String translate(String key, [Map<String, Object>? arguments]) {
    final translations = locale.languageCode == 'en' ? En.values : In.values;
    var result = translations[key] ?? In.values[key] ?? key;

    arguments?.forEach((name, value) {
      result = result.replaceAll('{$name}', value.toString());
    });
    return result;
  }

  static const delegate = _AppLocalizationsDelegate();
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (supported) => supported.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsContext on BuildContext {
  String tr(String key, [Map<String, Object>? arguments]) =>
      AppLocalizations.of(this).translate(key, arguments);
}
