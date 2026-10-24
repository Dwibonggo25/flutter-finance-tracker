import 'package:finance_project/features/transactions/domain/entities/finance_transaction.dart';
import 'package:finance_project/features/transactions/domain/extensions/finance_transaction_iterable_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final transactions = [
    FinanceTransaction(
      id: 'income-1',
      title: 'Salary',
      categoryKey: 'income',
      amount: 5000000,
      date: DateTime(2026, 10, 1),
      type: FinanceTransactionType.income,
    ),
    FinanceTransaction(
      id: 'expense-1',
      title: 'Rent',
      categoryKey: 'housing',
      amount: 1500000,
      date: DateTime(2026, 10, 2),
      type: FinanceTransactionType.expense,
    ),
    FinanceTransaction(
      id: 'expense-2',
      title: 'Food',
      categoryKey: 'needs',
      amount: 500000,
      date: DateTime(2026, 10, 3),
      type: FinanceTransactionType.expense,
    ),
  ];

  test('calculates total income and expense', () {
    expect(transactions.totalIncome, 5000000);
    expect(transactions.totalExpense, 2000000);
  });

  test('returns zero when the iterable is empty', () {
    const empty = <FinanceTransaction>[];

    expect(empty.totalIncome, 0);
    expect(empty.totalExpense, 0);
  });
}
