import 'package:finance_project/features/budgets/domain/entities/monthly_budget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds a stable month ID and calculates category totals', () {
    const budget = MonthlyBudget(
      year: 2026,
      month: 4,
      categoryLimits: {'housing': 2500000, 'needs': 750000},
    );

    expect(budget.id, '2026-04');
    expect(budget.totalLimit, 3250000);
    expect(budget.limitFor('housing'), 2500000);
    expect(budget.limitFor('other'), 0);
  });
}
