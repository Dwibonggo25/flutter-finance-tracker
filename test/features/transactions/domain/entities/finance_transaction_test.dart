import 'package:finance_project/features/transactions/domain/entities/finance_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('copyWith keeps identity while updating editable values', () {
    final original = FinanceTransaction(
      id: 'transaction-1',
      title: 'Coffee',
      categoryKey: 'needs',
      amount: 25000,
      date: DateTime(2026, 10, 24),
      type: FinanceTransactionType.expense,
    );

    final updated = original.copyWith(title: 'Groceries', amount: 150000);

    expect(updated.id, original.id);
    expect(updated.title, 'Groceries');
    expect(updated.amount, 150000);
    expect(updated.categoryKey, original.categoryKey);
    expect(updated.type, original.type);
  });
}
