import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../libraries/core/formatters/rupiah_input_formatter.dart';
import '../../../../libraries/core/localization/app_localizations.dart';
import '../../../../libraries/core/localization/language_controller.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../../../libraries/core/theme/app_theme_context.dart';
import '../../../../shared/widget/dropdown_input.dart';
import '../../../budgets/domain/entities/monthly_budget.dart';
import '../../../budgets/domain/repositories/budget_repository.dart';
import '../../../budgets/presentation/bloc/budget_bloc.dart';
import '../../../budgets/presentation/bloc/budget_event.dart';
import '../../../budgets/presentation/bloc/budget_state.dart';
import '../../../categories/domain/entities/expense_category.dart';
import '../../../categories/domain/repositories/expense_category_repository.dart';
import '../../../categories/presentation/ui/expense_categories_page.dart';
import '../../../transactions/domain/entities/finance_transaction.dart';
import '../../../transactions/domain/extensions/finance_transaction_iterable_extension.dart';

class BudgetTab extends StatelessWidget {
  final List<FinanceTransaction> transactions;
  final List<ExpenseCategory> categories;
  final BudgetRepository budgetRepository;
  final ExpenseCategoryRepository categoryRepository;

  const BudgetTab({
    super.key,
    required this.transactions,
    required this.categories,
    required this.budgetRepository,
    required this.categoryRepository,
  });

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => BudgetBloc(budgetRepository)..add(const BudgetStarted()),
    child: _BudgetTabView(
      transactions: transactions,
      categories: categories,
      categoryRepository: categoryRepository,
    ),
  );
}

class _BudgetTabView extends StatelessWidget {
  final List<FinanceTransaction> transactions;
  final List<ExpenseCategory> categories;
  final ExpenseCategoryRepository categoryRepository;

  const _BudgetTabView({
    required this.transactions,
    required this.categories,
    required this.categoryRepository,
  });

  @override
  Widget build(BuildContext context) => BlocConsumer<BudgetBloc, BudgetState>(
    listenWhen: (previous, current) =>
        previous.status != current.status &&
        (current.status == BudgetStatus.saveSuccess ||
            current.status == BudgetStatus.failure),
    listener: (context, state) {
      if (state.status == BudgetStatus.saveSuccess) {
        _showBudgetMessage(context, LanguageKeys.budgetSaved);
      } else if (state.errorKey != null) {
        _showBudgetMessage(context, state.errorKey!);
      }
    },
    builder: (context, state) {
      final monthlyTransactions = transactions
          .where(
            (transaction) =>
                transaction.type == FinanceTransactionType.expense &&
                transaction.date.year == state.selectedMonth.year &&
                transaction.date.month == state.selectedMonth.month,
          )
          .toList(growable: false);
      final expense = monthlyTransactions.totalExpense;
      final budget = state.budget;

      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 112),
        children: [
          DropdownButtonFormField<DateTime>(
            key: ValueKey(state.selectedMonth),
            initialValue: state.selectedMonth,
            borderRadius: BorderRadius.circular(18),
            dropdownColor: context.surfaceColor,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            decoration: dropdownDecoration(
              context,
              context.tr(LanguageKeys.budgetMonth),
              icon: Icons.calendar_month_outlined,
            ),
            items: _availableMonths
                .map(
                  (month) => DropdownMenuItem(
                    value: month,
                    child: Text(_formatMonth(context, month)),
                  ),
                )
                .toList(growable: false),
            onChanged: state.isSaving
                ? null
                : (month) {
                    if (month != null) {
                      context.read<BudgetBloc>().add(BudgetMonthChanged(month));
                    }
                  },
          ),
          if (state.isInitialLoading) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(minHeight: 2),
          ],
          const SizedBox(height: 16),
          _BudgetSummary(expense: expense, limit: budget.totalLimit),
          if (budget.totalLimit <= 0 || expense >= budget.totalLimit * 0.8)
            _BudgetWarning(expense: expense, limit: budget.totalLimit),
          const SizedBox(height: 24),
          _BudgetSectionTitle(
            title: context.tr(LanguageKeys.expenseCategories),
            action: context.tr(LanguageKeys.manageCategories),
            onTap: () => _manageCategories(context),
          ),
          const SizedBox(height: 12),
          for (final category in categories)
            _CategoryBudget(
              icon: _iconForExpenseCategory(category),
              name: _categoryLabel(context, category.id, categories),
              used: _expenseForCategory(monthlyTransactions, category.id),
              limit: budget.limitFor(category.id),
              color: Color(category.colorValue),
              onTap: state.isSaving ? null : () => _editBudget(context, budget),
            ),
        ],
      );
    },
  );

  List<DateTime> get _availableMonths => List.generate(5, (index) {
    final now = DateTime.now();
    return DateTime(now.year, now.month - index);
  });

  Future<void> _editBudget(BuildContext context, MonthlyBudget budget) async {
    final updated = await showModalBottomSheet<MonthlyBudget>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _BudgetEditorSheet(budget: budget, categories: categories),
    );
    if (updated == null || !context.mounted) return;
    context.read<BudgetBloc>().add(BudgetSaveRequested(updated));
  }

  void _manageCategories(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExpenseCategoriesPage(repository: categoryRepository),
      ),
    );
  }

  void _showBudgetMessage(BuildContext context, String key) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.tr(key)),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _BudgetWarning extends StatelessWidget {
  final double expense;
  final double limit;

  const _BudgetWarning({required this.expense, required this.limit});

  @override
  Widget build(BuildContext context) {
    final isUnset = limit <= 0;
    final isExceeded = !isUnset && expense > limit;
    final color = isExceeded
        ? const Color(0xFFB54D2B)
        : const Color(0xFFD47618);
    final message = isUnset
        ? LanguageKeys.budgetSetupHint
        : isExceeded
        ? LanguageKeys.budgetExceeded
        : LanguageKeys.budgetAlmostReached;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isUnset ? Icons.tune_rounded : Icons.warning_amber_rounded,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.tr(message),
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetSummary extends StatelessWidget {
  final double expense;
  final double limit;

  const _BudgetSummary({required this.expense, required this.limit});

  @override
  Widget build(BuildContext context) {
    final progress = limit <= 0 ? 0.0 : (expense / limit).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0DA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  color: Color(0xFFD47618),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(LanguageKeys.expense),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      limit <= 0
                          ? context.tr(LanguageKeys.budgetNotSet)
                          : context.tr(LanguageKeys.spentOf, {
                              'spent': _formatCompactCurrency(expense),
                              'limit': _formatCompactCurrency(limit),
                            }),
                      style: const TextStyle(
                        color: Color(0xFF718078),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                limit <= 0 ? '—' : '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: Color(0xFFD47618),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: const Color(0xFFF2F0EA),
              color: const Color(0xFFE29A47),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetSectionTitle extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onTap;

  const _BudgetSectionTitle({
    required this.title,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
      TextButton(onPressed: onTap, child: Text(action)),
    ],
  );
}

class _CategoryBudget extends StatelessWidget {
  final IconData icon;
  final String name;
  final double used;
  final double limit;
  final Color color;
  final VoidCallback? onTap;

  const _CategoryBudget({
    required this.icon,
    required this.name,
    required this.used,
    required this.limit,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = limit <= 0 ? 0.0 : (used / limit).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: context.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: context.borderColor),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(icon, color: color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      limit <= 0 ? '—' : '${(progress * 100).round()}%',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(8),
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.12),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatCompactCurrency(used),
                      style: const TextStyle(
                        color: Color(0xFF66736C),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      limit <= 0
                          ? context.tr(LanguageKeys.notSet)
                          : context.tr(LanguageKeys.budgetLimit, {
                              'amount': _formatCompactCurrency(limit),
                            }),
                      style: const TextStyle(
                        color: Color(0xFF66736C),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BudgetEditorSheet extends StatefulWidget {
  final MonthlyBudget budget;
  final List<ExpenseCategory> categories;

  const _BudgetEditorSheet({required this.budget, required this.categories});

  @override
  State<_BudgetEditorSheet> createState() => _BudgetEditorSheetState();
}

class _BudgetEditorSheetState extends State<_BudgetEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final category in widget.categories)
        category.id: TextEditingController(
          text: widget.budget.limitFor(category.id) <= 0
              ? ''
              : formatRupiahInput(widget.budget.limitFor(category.id)),
        ),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            22,
            12,
            22,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9DFDB),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  context.tr(LanguageKeys.setMonthlyBudget),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatMonth(
                    context,
                    DateTime(widget.budget.year, widget.budget.month),
                  ),
                  style: const TextStyle(color: Color(0xFF718078)),
                ),
                const SizedBox(height: 20),
                for (final category in widget.categories) ...[
                  TextFormField(
                    controller: _controllers[category.id],
                    keyboardType: TextInputType.number,
                    inputFormatters: const [RupiahInputFormatter()],
                    decoration: InputDecoration(
                      labelText: _categoryLabel(
                        context,
                        category.id,
                        widget.categories,
                      ),
                      prefixIcon: Icon(_iconForExpenseCategory(category)),
                      prefixText: 'Rp ',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final amount = _parseCurrencyInput(value);
                      return amount == null || amount < 0
                          ? context.tr(LanguageKeys.amountInvalid)
                          : null;
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(
                      context.tr(LanguageKeys.saveBudget),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final limits = <String, double>{};
    for (final entry in _controllers.entries) {
      final amount = _parseCurrencyInput(entry.value.text) ?? 0;
      if (amount > 0) limits[entry.key] = amount;
    }
    Navigator.pop(
      context,
      MonthlyBudget(
        year: widget.budget.year,
        month: widget.budget.month,
        categoryLimits: limits,
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

double _expenseForCategory(
  Iterable<FinanceTransaction> transactions,
  String category,
) => transactions
    .where((transaction) => transaction.categoryKey == category)
    .fold<double>(0, (total, transaction) => total + transaction.amount);

String _formatMonth(BuildContext context, DateTime month) {
  final value = DateFormat(
    'MMMM yyyy',
    Localizations.localeOf(context).toLanguageTag(),
  ).format(month);
  return value.isEmpty
      ? value
      : '${value[0].toUpperCase()}${value.substring(1)}';
}

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
  return NumberFormat.currency(
    locale: LanguageController.instance.value.languageCode == 'id'
        ? 'id_ID'
        : 'en_US',
    symbol: 'Rp',
    decimalDigits: 0,
  ).format(amount);
}

double? _parseCurrencyInput(String value) => parseRupiah(value);
