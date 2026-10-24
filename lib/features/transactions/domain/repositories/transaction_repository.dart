import '../entities/finance_transaction.dart';

abstract interface class TransactionRepository {
  Stream<List<FinanceTransaction>> watchTransactions();

  Future<void> createTransaction(FinanceTransaction transaction);

  Future<void> updateTransaction(FinanceTransaction transaction);

  Future<void> deleteTransaction(String transactionId);
}
