import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../transactions/domain/entities/finance_transaction.dart';
import '../../../transactions/domain/extensions/finance_transaction_iterable_extension.dart';

class ReportExportService {
  const ReportExportService();

  String buildCsv(List<FinanceTransaction> transactions) {
    final rows = <List<dynamic>>[
      ['Date', 'Type', 'Category', 'Title', 'Note', 'Amount'],
      for (final item in transactions)
        [
          DateFormat('yyyy-MM-dd').format(item.date),
          item.type.name,
          item.categoryKey,
          item.title,
          item.note,
          item.amount,
        ],
    ];
    return const ListToCsvConverter().convert(rows);
  }

  Future<Uint8List> buildPdf(List<FinanceTransaction> transactions) async {
    final income = transactions.totalIncome;
    final expense = transactions.totalExpense;
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => [
          pw.Text(
            'Finance Project - Transaction Report',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
          ),
          pw.SizedBox(height: 18),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Income: ${_money(income)}'),
              pw.Text('Expense: ${_money(expense)}'),
              pw.Text('Balance: ${_money(income - expense)}'),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headers: const ['Date', 'Type', 'Category', 'Title', 'Amount'],
            data: [
              for (final item in transactions)
                [
                  DateFormat('yyyy-MM-dd').format(item.date),
                  item.type.name,
                  item.categoryKey,
                  item.title,
                  _money(item.amount),
                ],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFE0F2EA),
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.all(6),
          ),
        ],
      ),
    );
    return document.save();
  }

  Future<void> shareCsv(
    List<FinanceTransaction> transactions, {
    Rect? sharePositionOrigin,
  }) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/finance-report-${_stamp()}.csv');
    await file.writeAsString(buildCsv(transactions), flush: true);
    await _share(file, 'text/csv', sharePositionOrigin);
  }

  Future<void> sharePdf(
    List<FinanceTransaction> transactions, {
    Rect? sharePositionOrigin,
  }) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/finance-report-${_stamp()}.pdf');
    await file.writeAsBytes(await buildPdf(transactions), flush: true);
    await _share(file, 'application/pdf', sharePositionOrigin);
  }

  Future<void> _share(File file, String mimeType, Rect? origin) {
    return SharePlus.instance.share(
      ShareParams(
        subject: 'Finance Project report',
        text: 'Finance Project transaction report',
        files: [XFile(file.path, mimeType: mimeType)],
        sharePositionOrigin: origin,
      ),
    );
  }

  String _money(double value) => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(value);

  String _stamp() => DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
}
