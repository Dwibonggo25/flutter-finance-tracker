import 'package:flutter/material.dart';

import '../../libraries/core/theme/app_colors.dart';
import '../../libraries/core/theme/app_theme_context.dart';

InputDecoration dropdownDecoration(
  BuildContext context,
  String label, {
  IconData? icon,
  bool compact = false,
}) {
  return InputDecoration(
    labelText: label,
    isDense: compact,
    prefixIcon: icon == null ? null : Icon(icon, size: compact ? 20 : null),
    prefixIconConstraints: compact
        ? const BoxConstraints(minWidth: 42, minHeight: 40)
        : null,
    filled: true,
    fillColor: context.surfaceColor,
    contentPadding: EdgeInsets.symmetric(
      horizontal: compact ? 12 : 16,
      vertical: compact ? 10 : 18,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: context.borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
  );
}
