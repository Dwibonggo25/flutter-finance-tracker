import 'package:equatable/equatable.dart';

import '../../domain/entities/expense_category.dart';

sealed class ExpenseCategoriesEvent extends Equatable {
  const ExpenseCategoriesEvent();

  @override
  List<Object?> get props => [];
}

final class ExpenseCategoriesStarted extends ExpenseCategoriesEvent {
  const ExpenseCategoriesStarted();
}

final class ExpenseCategoriesUpdated extends ExpenseCategoriesEvent {
  final List<ExpenseCategory> categories;

  const ExpenseCategoriesUpdated(this.categories);

  @override
  List<Object?> get props => [categories];
}

final class ExpenseCategoriesSubscriptionFailed extends ExpenseCategoriesEvent {
  const ExpenseCategoriesSubscriptionFailed();
}

final class ExpenseCategoryAddRequested extends ExpenseCategoriesEvent {
  final String name;

  const ExpenseCategoryAddRequested(this.name);

  @override
  List<Object?> get props => [name];
}

final class ExpenseCategoryRenameRequested extends ExpenseCategoriesEvent {
  final ExpenseCategory category;
  final String newName;

  const ExpenseCategoryRenameRequested({
    required this.category,
    required this.newName,
  });

  @override
  List<Object?> get props => [category, newName];
}

final class ExpenseCategoryDeleteRequested extends ExpenseCategoriesEvent {
  final String categoryId;

  const ExpenseCategoryDeleteRequested(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}
