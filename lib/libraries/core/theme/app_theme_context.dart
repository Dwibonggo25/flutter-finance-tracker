import 'package:flutter/material.dart';

extension AppThemeContext on BuildContext {
  Color get surfaceColor => Theme.of(this).colorScheme.surface;

  Color get borderColor => Theme.of(this).dividerColor;
}
