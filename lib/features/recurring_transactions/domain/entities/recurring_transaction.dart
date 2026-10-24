import '../../../transactions/domain/entities/finance_transaction.dart';

class RecurringTransaction {
  final String id;
  final String title;
  final double amount;
  final FinanceTransactionType type;
  final String categoryKey;
  final int dayOfMonth;
  final int reminderDaysBefore;
  final bool isActive;
  final String note;

  const RecurringTransaction({
    this.id = '',
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryKey,
    required this.dayOfMonth,
    this.reminderDaysBefore = 1,
    this.isActive = true,
    this.note = '',
  });

  RecurringTransaction copyWith({
    String? id,
    String? title,
    double? amount,
    FinanceTransactionType? type,
    String? categoryKey,
    int? dayOfMonth,
    int? reminderDaysBefore,
    bool? isActive,
    String? note,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryKey: categoryKey ?? this.categoryKey,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      isActive: isActive ?? this.isActive,
      note: note ?? this.note,
    );
  }

  DateTime nextDueDate(DateTime from) {
    var dueDate = _dateForMonth(from.year, from.month);
    final today = DateTime(from.year, from.month, from.day);
    if (dueDate.isBefore(today)) {
      dueDate = _dateForMonth(from.year, from.month + 1);
    }
    return dueDate;
  }

  DateTime nextReminderDate(DateTime from) {
    var dueDate = nextDueDate(from);
    var reminder = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      9,
    ).subtract(Duration(days: reminderDaysBefore));
    if (!reminder.isAfter(from)) {
      dueDate = _dateForMonth(dueDate.year, dueDate.month + 1);
      reminder = DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
        9,
      ).subtract(Duration(days: reminderDaysBefore));
    }
    return reminder;
  }

  DateTime _dateForMonth(int year, int month) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, dayOfMonth.clamp(1, lastDay));
  }
}
