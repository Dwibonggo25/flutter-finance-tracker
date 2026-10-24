import 'package:finance_project/features/reports/domain/services/report_export_service.dart';
import 'package:finance_project/features/transactions/domain/entities/finance_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildCsv exports a header and transaction fields', () {
    final result = const ReportExportService().buildCsv([
      FinanceTransaction(
        title: 'Salary',
        categoryKey: 'salary',
        amount: 10000000,
        date: DateTime(2026, 10, 24),
        type: FinanceTransactionType.income,
        note: 'October',
      ),
    ]);

    expect(result, contains('Date,Type,Category,Title,Note,Amount'));
    expect(
      result,
      contains('2026-10-24,income,salary,Salary,October,10000000'),
    );
  });
}
