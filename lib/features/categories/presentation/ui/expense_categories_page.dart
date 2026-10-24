import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../libraries/core/localization/app_localizations.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../../../shared/widget/category_name_dialog.dart';
import '../../domain/entities/expense_category.dart';
import '../../domain/repositories/expense_category_repository.dart';
import '../bloc/expense_categories_bloc.dart';
import '../bloc/expense_categories_event.dart';
import '../bloc/expense_categories_state.dart';

class ExpenseCategoriesPage extends StatelessWidget {
  final ExpenseCategoryRepository repository;

  const ExpenseCategoriesPage({super.key, required this.repository});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        ExpenseCategoriesBloc(repository)
          ..add(const ExpenseCategoriesStarted()),
    child: const _ExpenseCategoriesView(),
  );
}

class _ExpenseCategoriesView extends StatelessWidget {
  const _ExpenseCategoriesView();

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<ExpenseCategoriesBloc, ExpenseCategoriesState>(
        listenWhen: (previous, current) =>
            current.status == ExpenseCategoriesStatus.failure &&
            (previous.status != current.status ||
                previous.errorKey != current.errorKey),
        listener: (context, state) {
          final errorKey = state.errorKey;
          if (errorKey != null) _message(context, errorKey);
        },
        builder: (context, state) => Scaffold(
          appBar: AppBar(
            surfaceTintColor: Colors.transparent,
            title: Text(context.tr(LanguageKeys.manageCategories)),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: state.isSubmitting
                ? null
                : () => _openNameDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: Text(context.tr(LanguageKeys.addCategory)),
          ),
          body: _body(context, state),
        ),
      );

  Widget _body(BuildContext context, ExpenseCategoriesState state) {
    if (state.isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == ExpenseCategoriesStatus.failure &&
        state.categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.tr(state.errorKey ?? LanguageKeys.categoryLoadFailed)),
            const SizedBox(height: 8),
            IconButton(
              onPressed: () => context.read<ExpenseCategoriesBloc>().add(
                const ExpenseCategoriesStarted(),
              ),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: state.categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final category = state.categories[index];
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
              enabled: !state.isSubmitting,
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
  }

  Future<void> _openNameDialog(
    BuildContext context, [
    ExpenseCategory? category,
  ]) async {
    final value = await showDialog<String>(
      context: context,
      builder: (_) => CategoryNameDialog(
        isEditing: category != null,
        initialName: category == null
            ? ''
            : category.isDefault
            ? context.tr(category.id)
            : category.name,
      ),
    );
    if (value == null || !context.mounted) return;
    final bloc = context.read<ExpenseCategoriesBloc>();
    if (category == null) {
      bloc.add(ExpenseCategoryAddRequested(value));
    } else {
      bloc.add(
        ExpenseCategoryRenameRequested(category: category, newName: value),
      );
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
    context.read<ExpenseCategoriesBloc>().add(
      ExpenseCategoryDeleteRequested(category.id),
    );
  }

  void _message(BuildContext context, String key) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.tr(key))));
  }
}

IconData _categoryIcon(String key) => switch (key) {
  'home' => Icons.home_rounded,
  'shopping' => Icons.shopping_bag_rounded,
  'transport' => Icons.directions_car_filled_rounded,
  'receipt' => Icons.receipt_long_rounded,
  _ => Icons.category_rounded,
};
