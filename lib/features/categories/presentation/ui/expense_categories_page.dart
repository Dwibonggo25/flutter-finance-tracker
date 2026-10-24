import 'package:flutter/material.dart';

import '../../../../libraries/core/localization/app_localizations.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../domain/entities/expense_category.dart';
import '../../domain/repositories/expense_category_repository.dart';

class ExpenseCategoriesPage extends StatelessWidget {
  final ExpenseCategoryRepository repository;

  const ExpenseCategoriesPage({super.key, required this.repository});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      surfaceTintColor: Colors.transparent,
      title: Text(context.tr(LanguageKeys.manageCategories)),
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _openNameDialog(context),
      icon: const Icon(Icons.add_rounded),
      label: Text(context.tr(LanguageKeys.addCategory)),
    ),
    body: StreamBuilder<List<ExpenseCategory>>(
      stream: repository.watchCategories(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          itemCount: snapshot.data!.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final category = snapshot.data![index];
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(
                    category.colorValue,
                  ).withValues(alpha: 0.12),
                  foregroundColor: Color(category.colorValue),
                  child: Icon(_categoryIcon(category.iconKey)),
                ),
                title: Text(
                  category.isDefault ? context.tr(category.id) : category.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) => value == 'edit'
                      ? _openNameDialog(context, category)
                      : _delete(context, category),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(context.tr(LanguageKeys.edit)),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(context.tr(LanguageKeys.delete)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ),
  );

  Future<void> _openNameDialog(
    BuildContext context, [
    ExpenseCategory? category,
  ]) async {
    final value = await showDialog<String>(
      context: context,
      builder: (_) => _CategoryNameDialog(
        isEditing: category != null,
        initialName: category == null
            ? ''
            : category.isDefault
            ? context.tr(category.id)
            : category.name,
      ),
    );
    if (value == null || !context.mounted) return;
    try {
      if (category == null) {
        await repository.addCategory(value);
      } else {
        await repository.renameCategory(category, value);
      }
    } catch (_) {
      if (context.mounted) _message(context, LanguageKeys.categorySaveFailed);
    }
  }

  Future<void> _delete(BuildContext context, ExpenseCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr(LanguageKeys.deleteCategory)),
        content: Text(dialogContext.tr(LanguageKeys.deleteCategoryWarning)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.tr(LanguageKeys.cancel)),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.tr(LanguageKeys.delete)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await repository.deleteCategory(category.id);
    } catch (_) {
      if (context.mounted) _message(context, LanguageKeys.categoryDeleteFailed);
    }
  }

  void _message(BuildContext context, String key) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.tr(key))));
  }
}

class _CategoryNameDialog extends StatefulWidget {
  final bool isEditing;
  final String initialName;

  const _CategoryNameDialog({
    required this.isEditing,
    required this.initialName,
  });

  @override
  State<_CategoryNameDialog> createState() => _CategoryNameDialogState();
}

class _CategoryNameDialogState extends State<_CategoryNameDialog> {
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

IconData _categoryIcon(String key) => switch (key) {
  'home' => Icons.home_rounded,
  'shopping' => Icons.shopping_bag_rounded,
  'transport' => Icons.directions_car_filled_rounded,
  'receipt' => Icons.receipt_long_rounded,
  _ => Icons.category_rounded,
};
