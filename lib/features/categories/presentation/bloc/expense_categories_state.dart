import 'package:equatable/equatable.dart';

import '../../domain/entities/expense_category.dart';

enum ExpenseCategoriesStatus { initial, loading, loaded, submitting, failure }

final class ExpenseCategoriesState extends Equatable {
  final ExpenseCategoriesStatus status;
  final List<ExpenseCategory> categories;
  final String? errorKey;

  const ExpenseCategoriesState({
    this.status = ExpenseCategoriesStatus.initial,
    this.categories = const [],
    this.errorKey,
  });

  bool get isInitialLoading =>
      categories.isEmpty &&
      (status == ExpenseCategoriesStatus.initial ||
          status == ExpenseCategoriesStatus.loading);

  bool get isSubmitting => status == ExpenseCategoriesStatus.submitting;

  ExpenseCategoriesState copyWith({
    ExpenseCategoriesStatus? status,
    List<ExpenseCategory>? categories,
    String? errorKey,
    bool clearError = false,
  }) => ExpenseCategoriesState(
    status: status ?? this.status,
    categories: categories ?? this.categories,
    errorKey: clearError ? null : errorKey ?? this.errorKey,
  );

  @override
  List<Object?> get props => [status, categories, errorKey];
}
