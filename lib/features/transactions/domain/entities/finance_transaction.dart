enum FinanceTransactionType { income, expense }

class FinanceTransaction {
  final String id;
  final String title;
  final String categoryKey;
  final double amount;
  final DateTime date;
  final FinanceTransactionType type;
  final String note;

  const FinanceTransaction({
    this.id = '',
    required this.title,
    required this.categoryKey,
    required this.amount,
    required this.date,
    required this.type,
    this.note = '',
  });

  FinanceTransaction copyWith({
    String? id,
    String? title,
    String? categoryKey,
    double? amount,
    DateTime? date,
    FinanceTransactionType? type,
    String? note,
  }) {
    return FinanceTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      categoryKey: categoryKey ?? this.categoryKey,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      note: note ?? this.note,
    );
  }
}
