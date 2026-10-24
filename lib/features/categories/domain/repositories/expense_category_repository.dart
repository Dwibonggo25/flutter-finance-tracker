import '../entities/expense_category.dart';

abstract interface class ExpenseCategoryRepository {
  Stream<List<ExpenseCategory>> watchCategories();

  Future<void> ensureDefaultCategories();

  Future<void> addCategory(String name);

  Future<void> renameCategory(ExpenseCategory category, String newName);

  Future<void> deleteCategory(String categoryId);
}
