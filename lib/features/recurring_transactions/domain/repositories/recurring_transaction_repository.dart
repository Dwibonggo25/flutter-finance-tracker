import '../entities/recurring_transaction.dart';

abstract interface class RecurringTransactionRepository {
  Stream<List<RecurringTransaction>> watchRecurringTransactions();

  Future<String> createRecurringTransaction(RecurringTransaction transaction);

  Future<void> updateRecurringTransaction(RecurringTransaction transaction);

  Future<void> deleteRecurringTransaction(String transactionId);
}
