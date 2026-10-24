import 'dart:math' as math;

import 'package:finance_project/features/categories/domain/entities/expense_category.dart';
import 'package:finance_project/features/reports/domain/services/report_export_service.dart';
import 'package:finance_project/features/transactions/domain/entities/finance_transaction.dart';
import 'package:finance_project/features/transactions/domain/extensions/finance_transaction_iterable_extension.dart';
import 'package:finance_project/libraries/core/localization/app_localizations.dart';
import 'package:finance_project/libraries/core/localization/language_controller.dart';
import 'package:finance_project/libraries/core/localization/language_keys.dart';
import 'package:finance_project/libraries/core/theme/app_colors.dart';
import 'package:finance_project/libraries/core/theme/app_theme_context.dart';
import 'package:finance_project/shared/widget/dropdown_input.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportsTab extends StatefulWidget {
  final List<FinanceTransaction> transactions;
  final List<ExpenseCategory> categories;
  final bool isActive;

  const ReportsTab({
    super.key,
    required this.transactions,
    required this.categories,
    required this.isActive,
  });

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  int _periodMonths = 6;
  String _category = LanguageKeys.all;
  final _exportService = const ReportExportService();

  @override
  Widget build(BuildContext context) {
    final selectedCategory =
        widget.categories.any((category) => category.id == _category)
        ? _category
        : LanguageKeys.all;
    final now = DateTime.now();
    final firstMonth = DateTime(now.year, now.month - _periodMonths + 1);
    final filtered = widget.transactions
        .where((transaction) {
          final transactionMonth = DateTime(
            transaction.date.year,
            transaction.date.month,
          );
          final inPeriod = !transactionMonth.isBefore(firstMonth);
          final inCategory =
              selectedCategory == LanguageKeys.all ||
              transaction.categoryKey == selectedCategory;
          return inPeriod && inCategory;
        })
        .toList(growable: false);
    final monthlyData = List.generate(_periodMonths, (index) {
      final month = DateTime(firstMonth.year, firstMonth.month + index);
      final items = filtered.where(
        (transaction) =>
            transaction.date.year == month.year &&
            transaction.date.month == month.month,
      );
      return _MonthlyReportData(
        month: month,
        income: items.totalIncome,
        expense: items.totalExpense,
      );
    });
    final maxAmount = monthlyData.fold<double>(0, (maximum, data) {
      return math.max(maximum, math.max(data.income, data.expense));
    });
    final income = filtered.totalIncome;
    final expense = filtered.totalExpense;
    final currentExpense = monthlyData.isEmpty ? 0.0 : monthlyData.last.expense;
    final previousExpense = monthlyData.length < 2
        ? 0.0
        : monthlyData[monthlyData.length - 2].expense;
    final expenseChange = previousExpense <= 0
        ? (currentExpense > 0 ? 100.0 : 0.0)
        : ((currentExpense - previousExpense) / previousExpense) * 100;
    final categoryTotals = <String, double>{
      for (final category in widget.categories)
        category.id: filtered
            .where(
              (transaction) =>
                  transaction.type == FinanceTransactionType.expense &&
                  transaction.categoryKey == category.id,
            )
            .fold(0, (total, transaction) => total + transaction.amount),
    };
    final maxCategory = categoryTotals.values.fold<double>(
      0,
      (maximum, value) => math.max(maximum, value),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 112),
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: _periodMonths,
                isExpanded: true,
                borderRadius: BorderRadius.circular(18),
                dropdownColor: context.surfaceColor,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                decoration: dropdownDecoration(
                  context,
                  context.tr(LanguageKeys.period),
                  icon: Icons.date_range_outlined,
                  compact: true,
                ),
                items: const [3, 6, 12]
                    .map(
                      (months) => DropdownMenuItem(
                        value: months,
                        child: Text(
                          context.tr(LanguageKeys.monthCount, {
                            'count': '$months',
                          }),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) setState(() => _periodMonths = value);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                isExpanded: true,
                borderRadius: BorderRadius.circular(18),
                dropdownColor: context.surfaceColor,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                decoration: dropdownDecoration(
                  context,
                  context.tr(LanguageKeys.category),
                  icon: Icons.category_outlined,
                  compact: true,
                ),
                items: [
                  DropdownMenuItem(
                    value: LanguageKeys.all,
                    child: Text(
                      context.tr(LanguageKeys.all),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ...widget.categories.map(
                    (category) => DropdownMenuItem(
                      value: category.id,
                      child: Text(
                        _categoryLabel(context, category.id, widget.categories),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: Builder(
            builder: (buttonContext) => PopupMenuButton<String>(
              tooltip: context.tr(LanguageKeys.exportReport),
              borderRadius: BorderRadius.circular(16),
              onSelected: (format) => _export(
                buttonContext,
                format: format,
                transactions: filtered,
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'csv',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.table_view_rounded),
                    title: Text(context.tr(LanguageKeys.exportCsv)),
                  ),
                ),
                PopupMenuItem(
                  value: 'pdf',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.picture_as_pdf_rounded),
                    title: Text(context.tr(LanguageKeys.exportPdf)),
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.ios_share_rounded, size: 19),
                    const SizedBox(width: 8),
                    Text(
                      context.tr(LanguageKeys.export),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(LanguageKeys.monthlyCashFlow),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr(LanguageKeys.cashFlowDescription),
                style: const TextStyle(color: Color(0xFF718078), fontSize: 13),
              ),
              const SizedBox(height: 28),
              TweenAnimationBuilder<double>(
                tween: Tween(end: widget.isActive ? 1 : 0),
                duration: widget.isActive
                    ? const Duration(milliseconds: 900)
                    : Duration.zero,
                curve: Curves.easeOutCubic,
                builder: (context, progress, _) => SizedBox(
                  height: 160,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: monthlyData
                          .map(
                            (data) => _MonthlyReportBars(
                              data: data,
                              maxAmount: maxAmount,
                              progress: progress,
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ChartLegend(
                    color: const Color(0xFF258A63),
                    label: context.tr(LanguageKeys.income),
                  ),
                  const SizedBox(width: 18),
                  _ChartLegend(
                    color: const Color(0xFFE29A47),
                    label: context.tr(LanguageKeys.expense),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _MonthlyComparisonCard(
          change: expenseChange,
          currentExpense: currentExpense,
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(LanguageKeys.expenseByCategory),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              TweenAnimationBuilder<double>(
                tween: Tween(end: widget.isActive ? 1 : 0),
                duration: widget.isActive
                    ? const Duration(milliseconds: 1050)
                    : Duration.zero,
                curve: Curves.easeOutCubic,
                builder: (context, progress, _) => Column(
                  children: [
                    for (final category in widget.categories)
                      if ((categoryTotals[category.id] ?? 0) > 0)
                        _CategoryReportRow(
                          label: _categoryLabel(
                            context,
                            category.id,
                            widget.categories,
                          ),
                          icon: _iconForExpenseCategory(category),
                          amount: categoryTotals[category.id] ?? 0,
                          maxAmount: maxCategory,
                          progress: progress,
                          color: Color(category.colorValue),
                        ),
                    if (maxCategory <= 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          context.tr(LanguageKeys.noExpenseData),
                          style: const TextStyle(color: Color(0xFF718078)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.auto_graph_rounded,
                color: AppColors.primary,
                size: 30,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  context.tr(LanguageKeys.moneySaved, {
                    'amount': _formatCurrency(income - expense),
                  }),
                  style: const TextStyle(
                    color: AppColors.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _export(
    BuildContext buttonContext, {
    required String format,
    required List<FinanceTransaction> transactions,
  }) async {
    final box = buttonContext.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    try {
      if (format == 'csv') {
        await _exportService.shareCsv(
          transactions,
          sharePositionOrigin: origin,
        );
      } else {
        await _exportService.sharePdf(
          transactions,
          sharePositionOrigin: origin,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr(LanguageKeys.exportSuccess))),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr(LanguageKeys.exportFailed))),
        );
      }
    }
  }
}

class _MonthlyReportData {
  final DateTime month;
  final double income;
  final double expense;

  const _MonthlyReportData({
    required this.month,
    required this.income,
    required this.expense,
  });
}

class _MonthlyReportBars extends StatelessWidget {
  final _MonthlyReportData data;
  final double maxAmount;
  final double progress;

  const _MonthlyReportBars({
    required this.data,
    required this.maxAmount,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final incomeHeight = maxAmount <= 0
        ? 0.0
        : (data.income / maxAmount) * 105 * progress;
    final expenseHeight = maxAmount <= 0
        ? 0.0
        : (data.expense / maxAmount) * 105 * progress;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          height: 108,
          width: 56,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ReportBar(
                height: incomeHeight,
                color: const Color(0xFF258A63),
                tooltip: _formatCurrency(data.income),
              ),
              const SizedBox(width: 5),
              _ReportBar(
                height: expenseHeight,
                color: const Color(0xFFE29A47),
                tooltip: _formatCurrency(data.expense),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          DateFormat(
            'MMM',
            Localizations.localeOf(context).toLanguageTag(),
          ).format(data.month),
          style: const TextStyle(
            color: Color(0xFF66736C),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ReportBar extends StatelessWidget {
  final double height;
  final Color color;
  final String tooltip;

  const _ReportBar({
    required this.height,
    required this.color,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final visibleHeight = height <= 0 ? 3.0 : math.max(5.0, height);
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 15,
        height: visibleHeight,
        decoration: BoxDecoration(
          color: height <= 0 ? color.withValues(alpha: 0.16) : color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        ),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF66736C), fontSize: 12),
        ),
      ],
    );
  }
}

class _MonthlyComparisonCard extends StatelessWidget {
  final double change;
  final double currentExpense;

  const _MonthlyComparisonCard({
    required this.change,
    required this.currentExpense,
  });

  @override
  Widget build(BuildContext context) {
    final increased = change > 0.05;
    final decreased = change < -0.05;
    final color = increased
        ? const Color(0xFFB54D2B)
        : decreased
        ? const Color(0xFF19704E)
        : const Color(0xFF66736C);
    final key = increased
        ? LanguageKeys.expenseIncreased
        : decreased
        ? LanguageKeys.expenseDecreased
        : LanguageKeys.expenseUnchanged;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            increased
                ? Icons.trending_up_rounded
                : decreased
                ? Icons.trending_down_rounded
                : Icons.trending_flat_rounded,
            color: color,
            size: 30,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatCurrency(currentExpense),
                  style: TextStyle(
                    color: color,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  context.tr(key, {'percent': change.abs().toStringAsFixed(0)}),
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryReportRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final double amount;
  final double maxAmount;
  final double progress;
  final Color color;

  const _CategoryReportRow({
    required this.label,
    required this.icon,
    required this.amount,
    required this.maxAmount,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final value = maxAmount <= 0 ? 0.0 : (amount / maxAmount) * progress;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                _formatCompactCurrency(amount),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 7,
            borderRadius: BorderRadius.circular(8),
            color: color,
            backgroundColor: color.withValues(alpha: 0.12),
          ),
        ],
      ),
    );
  }
}

IconData _iconForExpenseCategory(ExpenseCategory category) {
  return switch (category.iconKey) {
    'home' => Icons.home_rounded,
    'shopping' => Icons.shopping_bag_rounded,
    'transport' => Icons.directions_car_filled_rounded,
    'receipt' => Icons.receipt_long_rounded,
    _ => Icons.category_rounded,
  };
}

String _categoryLabel(
  BuildContext context,
  String categoryId,
  List<ExpenseCategory> categories,
) {
  for (final category in categories) {
    if (category.id == categoryId) {
      return category.isDefault ? context.tr(category.id) : category.name;
    }
  }
  return context.tr(categoryId);
}

String _formatCurrency(double amount) => NumberFormat.currency(
  locale: LanguageController.instance.value.languageCode == 'id'
      ? 'id_ID'
      : 'en_US',
  symbol: 'Rp',
  decimalDigits: 0,
).format(amount);

String _formatCompactCurrency(double amount) {
  if (amount >= 1000000) {
    final value = amount / 1000000;
    final digits = value.truncateToDouble() == value ? 0 : 1;
    final suffix = LanguageController.instance.translate(
      LanguageKeys.millionShort,
    );
    return 'Rp${value.toStringAsFixed(digits)} $suffix';
  }
  if (amount >= 1000) {
    final suffix = LanguageController.instance.translate(
      LanguageKeys.thousandShort,
    );
    return 'Rp${(amount / 1000).round()} $suffix';
  }
  return _formatCurrency(amount);
}
