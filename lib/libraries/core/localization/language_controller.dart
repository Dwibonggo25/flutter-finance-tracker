import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_localizations.dart';

class LanguageController extends ValueNotifier<Locale> {
  static const _storageKey = 'selected_language';
  static final instance = LanguageController._();

  SharedPreferences? _preferences;

  LanguageController._() : super(const Locale('id'));

  void initialize(SharedPreferences preferences) {
    _preferences = preferences;
    final savedLanguage = preferences.getString(_storageKey);
    if (savedLanguage == 'en' || savedLanguage == 'id') {
      value = Locale(savedLanguage!);
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    if (languageCode != 'id' && languageCode != 'en') return;
    value = Locale(languageCode);
    await _preferences?.setString(_storageKey, languageCode);
  }

  String translate(String key, [Map<String, Object>? arguments]) =>
      AppLocalizations(value).translate(key, arguments);
}
