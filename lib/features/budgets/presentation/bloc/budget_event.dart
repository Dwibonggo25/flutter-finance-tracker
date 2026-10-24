import 'package:equatable/equatable.dart';

import '../../domain/entities/monthly_budget.dart';

sealed class BudgetEvent extends Equatable {
  const BudgetEvent();

  @override
  List<Object?> get props => [];
}

final class BudgetStarted extends BudgetEvent {
  const BudgetStarted();
}

final class BudgetMonthChanged extends BudgetEvent {
  final DateTime month;

  const BudgetMonthChanged(this.month);

  @override
  List<Object?> get props => [month];
}

final class BudgetUpdated extends BudgetEvent {
  final MonthlyBudget budget;

  const BudgetUpdated(this.budget);

  @override
  List<Object?> get props => [budget];
}

final class BudgetSubscriptionFailed extends BudgetEvent {
  const BudgetSubscriptionFailed();
}

final class BudgetSaveRequested extends BudgetEvent {
  final MonthlyBudget budget;

  const BudgetSaveRequested(this.budget);

  @override
  List<Object?> get props => [budget];
}
