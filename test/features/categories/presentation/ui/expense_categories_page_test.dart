import 'package:finance_project/features/categories/domain/entities/expense_category.dart';
import 'package:finance_project/features/categories/domain/repositories/expense_category_repository.dart';
import 'package:finance_project/features/categories/presentation/ui/expense_categories_page.dart';
import 'package:finance_project/libraries/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('adds a category without disposing the dialog controller early', (
    tester,
  ) async {
    final repository = _FakeExpenseCategoryRepository();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: ExpenseCategoriesPage(repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add category'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Health');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(repository.addedNames, ['Health']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not submit an empty category name', (tester) async {
    final repository = _FakeExpenseCategoryRepository();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: ExpenseCategoriesPage(repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add category'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pump();

    expect(repository.addedNames, isEmpty);
    expect(find.byType(AlertDialog), findsOneWidget);
  });
}

class _FakeExpenseCategoryRepository implements ExpenseCategoryRepository {
  final List<String> addedNames = [];

  @override
  Stream<List<ExpenseCategory>> watchCategories() =>
      Stream.value(const <ExpenseCategory>[]);

  @override
  Future<void> addCategory(String name) async => addedNames.add(name);

  @override
  Future<void> deleteCategory(String categoryId) async {}

  @override
  Future<void> ensureDefaultCategories() async {}

  @override
  Future<void> renameCategory(ExpenseCategory category, String newName) async {}
}
