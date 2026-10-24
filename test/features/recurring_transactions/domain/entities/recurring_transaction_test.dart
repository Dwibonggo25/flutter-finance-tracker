import 'package:finance_project/features/recurring_transactions/domain/entities/recurring_transaction.dart';
import 'package:finance_project/features/transactions/domain/entities/finance_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const transaction = RecurringTransaction(
    title: 'Monthly bill',
    amount: 250000,
    type: FinanceTransactionType.expense,
    categoryKey: 'bills',
    dayOfMonth: 31,
    reminderDaysBefore: 3,
  );

  test('clamps due date to the last day of a short month', () {
    expect(
      transaction.nextDueDate(DateTime(2026, 2, 1)),
      DateTime(2026, 2, 28),
    );
  });

  test('moves due date to the next month after it has passed', () {
    expect(
      transaction.nextDueDate(DateTime(2026, 5, 1)),
      DateTime(2026, 5, 31),
    );
  });

  test('calculates the next reminder before the due date', () {
    expect(
      transaction.nextReminderDate(DateTime(2026, 10, 1)),
      DateTime(2026, 10, 28, 9),
    );
  });
}
