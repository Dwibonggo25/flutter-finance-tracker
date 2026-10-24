import 'package:equatable/equatable.dart';

import '../../domain/entities/monthly_budget.dart';

enum BudgetStatus { initial, loading, loaded, saving, saveSuccess, failure }

final class BudgetState extends Equatable {
  final BudgetStatus status;
  final DateTime selectedMonth;
  final MonthlyBudget budget;
  final String? errorKey;

  const BudgetState({
    required this.selectedMonth,
    required this.budget,
    this.status = BudgetStatus.initial,
    this.errorKey,
  });

  factory BudgetState.initial(DateTime month) {
    final normalizedMonth = DateTime(month.year, month.month);
    return BudgetState(
      selectedMonth: normalizedMonth,
      budget: MonthlyBudget(
        year: normalizedMonth.year,
        month: normalizedMonth.month,
      ),
    );
  }

  bool get isInitialLoading =>
      status == BudgetStatus.initial || status == BudgetStatus.loading;

  bool get isSaving => status == BudgetStatus.saving;

  BudgetState copyWith({
    BudgetStatus? status,
    DateTime? selectedMonth,
    MonthlyBudget? budget,
    String? errorKey,
    bool clearError = false,
  }) => BudgetState(
    status: status ?? this.status,
    selectedMonth: selectedMonth ?? this.selectedMonth,
    budget: budget ?? this.budget,
    errorKey: clearError ? null : errorKey ?? this.errorKey,
  );

  @override
  List<Object?> get props => [status, selectedMonth, budget, errorKey];
}
