import 'package:finance_project/libraries/core/localization/app_localizations.dart';
import 'package:finance_project/libraries/core/localization/language_keys.dart';
import 'package:finance_project/libraries/core/localization/languages/en.dart';
import 'package:finance_project/libraries/core/localization/languages/in.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('English and Indonesian contain the same language keys', () {
    expect(En.values.keys.toSet(), In.values.keys.toSet());
  });

  test('translates a key using the selected locale', () {
    const english = AppLocalizations(Locale('en'));
    const indonesian = AppLocalizations(Locale('id'));

    expect(english.translate(LanguageKeys.login), 'Log in');
    expect(indonesian.translate(LanguageKeys.login), 'Masuk');
  });

  test('replaces named arguments in translated text', () {
    const localization = AppLocalizations(Locale('en'));

    expect(
      localization.translate(LanguageKeys.moneySaved, {'amount': 'Rp5 M'}),
      'You saved Rp5 M this month.',
    );
  });
}
