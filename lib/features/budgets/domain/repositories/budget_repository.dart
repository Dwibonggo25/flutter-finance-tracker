import '../entities/monthly_budget.dart';

abstract interface class BudgetRepository {
  Stream<MonthlyBudget> watchMonthlyBudget(DateTime month);

  Future<void> saveMonthlyBudget(MonthlyBudget budget);
}
