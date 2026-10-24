import 'package:finance_project/features/categories/domain/entities/expense_category.dart';
import 'package:finance_project/features/transactions/domain/entities/finance_transaction.dart';
import 'package:finance_project/libraries/core/formatters/rupiah_input_formatter.dart';
import 'package:finance_project/libraries/core/localization/language_keys.dart';
import 'package:finance_project/libraries/core/theme/app_theme_context.dart';
import 'package:finance_project/shared/widget/dropdown_input.dart';
import 'package:flutter/material.dart';

import '../../../../libraries/core/localization/app_localizations.dart';

class TransactionFormSheet extends StatefulWidget {
  final FinanceTransaction? initialTransaction;
  final List<ExpenseCategory> categories;

  const TransactionFormSheet({
    super.key,
    required this.categories,
    this.initialTransaction,
  });

  @override
  State<TransactionFormSheet> createState() => _TransactionFormSheetState();
}

class _TransactionFormSheetState extends State<TransactionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  FinanceTransactionType _type = FinanceTransactionType.expense;
  String _category = LanguageKeys.other;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final transaction = widget.initialTransaction;
    if (transaction == null) return;

    _titleController.text = transaction.title;
    _amountController.text = formatRupiahInput(transaction.amount);
    _noteController.text = transaction.note;
    _type = transaction.type;
    _category = transaction.categoryKey;
    _date = transaction.date;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
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
                  context.tr(
                    widget.initialTransaction == null
                        ? LanguageKeys.addTransaction
                        : LanguageKeys.editTransaction,
                  ),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                SegmentedButton<FinanceTransactionType>(
                  segments: [
                    ButtonSegment(
                      value: FinanceTransactionType.expense,
                      label: Text(context.tr(LanguageKeys.expense)),
                      icon: const Icon(Icons.north_east_rounded),
                    ),
                    ButtonSegment(
                      value: FinanceTransactionType.income,
                      label: Text(context.tr(LanguageKeys.income)),
                      icon: const Icon(Icons.south_west_rounded),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (value) {
                    setState(() {
                      _type = value.first;
                      _category = _type == FinanceTransactionType.income
                          ? LanguageKeys.income
                          : widget.categories.first.id;
                    });
                  },
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  maxLength: 120,
                  decoration: InputDecoration(
                    labelText: context.tr(LanguageKeys.transactionName),
                    prefixIcon: const Icon(Icons.edit_note_rounded),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? context.tr(LanguageKeys.transactionNameRequired)
                      : null,
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [RupiahInputFormatter()],
                  decoration: InputDecoration(
                    labelText: context.tr(LanguageKeys.amount),
                    prefixText: 'Rp ',
                  ),
                  validator: (value) {
                    final amount = parseRupiah(value ?? '');
                    return amount == null || amount <= 0
                        ? context.tr(LanguageKeys.amountInvalid)
                        : null;
                  },
                ),
                const SizedBox(height: 14),
                if (_type == FinanceTransactionType.expense) ...[
                  DropdownButtonFormField<String>(
                    initialValue:
                        widget.categories.any(
                          (category) => category.id == _category,
                        )
                        ? _category
                        : widget.categories.first.id,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(18),
                    dropdownColor: context.surfaceColor,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    decoration: dropdownDecoration(
                      context,
                      context.tr(LanguageKeys.category),
                      icon: Icons.category_outlined,
                    ),
                    items: widget.categories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category.id,
                            child: Text(
                              _categoryLabel(
                                context,
                                category.id,
                                widget.categories,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value != null) setState(() => _category = value);
                    },
                  ),
                  const SizedBox(height: 14),
                ],
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(4),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: context.tr(LanguageKeys.transactionDate),
                      prefixIcon: const Icon(Icons.calendar_month_outlined),
                      suffixIcon: const Icon(Icons.expand_more_rounded),
                    ),
                    child: Text(
                      MaterialLocalizations.of(context).formatMediumDate(_date),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _noteController,
                  maxLength: 500,
                  minLines: 2,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: context.tr(LanguageKeys.noteOptional),
                    prefixIcon: const Icon(Icons.notes_rounded),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _submit,
                    child: Text(
                      context.tr(
                        widget.initialTransaction == null
                            ? LanguageKeys.saveTransaction
                            : LanguageKeys.updateTransaction,
                      ),
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

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final amount = parseRupiah(_amountController.text)!;
    Navigator.pop(
      context,
      FinanceTransaction(
        id: widget.initialTransaction?.id ?? '',
        title: _titleController.text.trim(),
        categoryKey: _type == FinanceTransactionType.income
            ? LanguageKeys.income
            : _category,
        amount: amount,
        date: _date,
        type: _type,
        note: _noteController.text.trim(),
      ),
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null && mounted) setState(() => _date = selected);
  }
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
