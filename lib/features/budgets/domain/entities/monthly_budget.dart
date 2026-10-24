class MonthlyBudget {
  final int year;
  final int month;
  final Map<String, double> categoryLimits;

  const MonthlyBudget({
    required this.year,
    required this.month,
    this.categoryLimits = const {},
  });

  String get id =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';

  double get totalLimit =>
      categoryLimits.values.fold(0, (total, amount) => total + amount);

  double limitFor(String category) => categoryLimits[category] ?? 0;
}
