import 'package:flutter/material.dart';

import '../../libraries/core/localization/app_localizations.dart';
import '../../libraries/core/localization/language_keys.dart';

class CategoryNameDialog extends StatefulWidget {
  final bool isEditing;
  final String initialName;

  const CategoryNameDialog({
    super.key,
    required this.isEditing,
    this.initialName = '',
  });

  @override
  State<CategoryNameDialog> createState() => _CategoryNameDialogState();
}

class _CategoryNameDialogState extends State<CategoryNameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      context.tr(
        widget.isEditing ? LanguageKeys.editCategory : LanguageKeys.addCategory,
      ),
    ),
    content: Form(
      key: _formKey,
      child: TextFormField(
        controller: _controller,
        autofocus: true,
        maxLength: 60,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: context.tr(LanguageKeys.categoryName),
        ),
        validator: (value) => value == null || value.trim().isEmpty
            ? context.tr(LanguageKeys.categoryName)
            : null,
        onFieldSubmitted: (_) => _save(),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.tr(LanguageKeys.cancel)),
      ),
      FilledButton(
        onPressed: _save,
        child: Text(context.tr(LanguageKeys.saveChanges)),
      ),
    ],
  );

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(context, _controller.text.trim());
  }
}
