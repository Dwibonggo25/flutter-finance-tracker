import '../entities/finance_transaction.dart';

extension FinanceTransactionIterableExtension on Iterable<FinanceTransaction> {
  double get totalIncome => totalForType(FinanceTransactionType.income);

  double get totalExpense => totalForType(FinanceTransactionType.expense);

  double totalForType(FinanceTransactionType type) => where(
    (transaction) => transaction.type == type,
  ).fold<double>(0, (total, transaction) => total + transaction.amount);
}
