import 'package:finance_project/features/recurring_transactions/domain/entities/recurring_transaction.dart';
import 'package:finance_project/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:finance_project/features/recurring_transactions/presentation/ui/recurring_transactions_page.dart';
import 'package:finance_project/libraries/core/localization/app_localizations.dart';
import 'package:finance_project/libraries/core/notifications/local_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows an empty state when no recurring transaction exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: RecurringTransactionsPage(
          repository: _EmptyRecurringRepository(),
          notificationService: LocalNotificationService.instance,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No recurring transactions yet.'), findsOneWidget);
    expect(find.byIcon(Icons.event_repeat_rounded), findsOneWidget);
  });
}

class _EmptyRecurringRepository implements RecurringTransactionRepository {
  @override
  Stream<List<RecurringTransaction>> watchRecurringTransactions() =>
      Stream.value(const []);

  @override
  Future<String> createRecurringTransaction(RecurringTransaction transaction) =>
      throw UnimplementedError();

  @override
  Future<void> deleteRecurringTransaction(String transactionId) =>
      throw UnimplementedError();

  @override
  Future<void> updateRecurringTransaction(RecurringTransaction transaction) =>
      throw UnimplementedError();
}
