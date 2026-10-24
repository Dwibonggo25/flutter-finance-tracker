import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ValueNotifier<ThemeMode> {
  static const _storageKey = 'selected_theme_mode';
  static final instance = ThemeController._();

  SharedPreferences? _preferences;

  ThemeController._() : super(ThemeMode.light);

  void initialize(SharedPreferences preferences) {
    _preferences = preferences;
    value = preferences.getString(_storageKey) == 'dark'
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  Future<void> changeTheme(ThemeMode mode) async {
    if (mode != ThemeMode.light && mode != ThemeMode.dark) return;
    value = mode;
    await _preferences?.setString(
      _storageKey,
      mode == ThemeMode.dark ? 'dark' : 'light',
    );
  }
}
