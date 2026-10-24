import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../libraries/core/localization/app_localizations.dart';
import '../../../../libraries/core/formatters/rupiah_input_formatter.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../../../libraries/core/notifications/local_notification_service.dart';
import '../../../../libraries/core/theme/app_colors.dart';
import '../../../transactions/domain/entities/finance_transaction.dart';
import '../../domain/entities/recurring_transaction.dart';
import '../../domain/repositories/recurring_transaction_repository.dart';

class RecurringTransactionsPage extends StatelessWidget {
  final RecurringTransactionRepository repository;
  final LocalNotificationService notificationService;

  const RecurringTransactionsPage({
    super.key,
    required this.repository,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        title: Text(context.tr(LanguageKeys.recurringTransactions)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(context.tr(LanguageKeys.addRecurringTransaction)),
      ),
      body: StreamBuilder<List<RecurringTransaction>>(
        stream: repository.watchRecurringTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 48),
                    const SizedBox(height: 12),
                    Text(context.tr(LanguageKeys.transactionsLoadFailed)),
                  ],
                ),
              ),
            );
          }
          final items = snapshot.data ?? const <RecurringTransaction>[];
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.event_repeat_rounded,
                      size: 64,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr(LanguageKeys.noRecurringTransactions),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.tr(LanguageKeys.recurringSubtitle),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF718078)),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 104),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _RecurringCard(
              transaction: items[index],
              onEdit: () => _openForm(context, items[index]),
              onDelete: () => _delete(context, items[index]),
              onToggle: (active) => _toggle(context, items[index], active),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context, [
    RecurringTransaction? existing,
  ]) async {
    final value = await showModalBottomSheet<RecurringTransaction>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _RecurringTransactionForm(transaction: existing),
    );
    if (value == null || !context.mounted) return;
    try {
      late final RecurringTransaction saved;
      if (existing == null) {
        final id = await repository.createRecurringTransaction(value);
        saved = value.copyWith(id: id);
      } else {
        saved = value.copyWith(id: existing.id);
        await repository.updateRecurringTransaction(saved);
      }
      if (saved.isActive) {
        await notificationService.requestPermission();
        await notificationService.schedule(saved);
      } else {
        await notificationService.cancel(saved.id);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr(LanguageKeys.recurringSaved))),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr(LanguageKeys.recurringSaveFailed))),
        );
      }
    }
  }

  Future<void> _toggle(
    BuildContext context,
    RecurringTransaction transaction,
    bool active,
  ) async {
    try {
      final updated = transaction.copyWith(isActive: active);
      await repository.updateRecurringTransaction(updated);
      if (active) {
        await notificationService.requestPermission();
        await notificationService.schedule(updated);
      } else {
        await notificationService.cancel(updated.id);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr(LanguageKeys.recurringSaveFailed))),
        );
      }
    }
  }

  Future<void> _delete(
    BuildContext context,
    RecurringTransaction transaction,
  ) async {
    try {
      await repository.deleteRecurringTransaction(transaction.id);
      await notificationService.cancel(transaction.id);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr(LanguageKeys.recurringDeleteFailed)),
          ),
        );
      }
    }
  }
}

class _RecurringCard extends StatelessWidget {
  final RecurringTransaction transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  const _RecurringCard({
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final dueDate = transaction.nextDueDate(DateTime.now());
    final today = DateTime.now();
    final difference = dueDate
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
    final color = transaction.type == FinanceTransactionType.income
        ? const Color(0xFF258A63)
        : const Color(0xFFE29A47);
    final amount = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(transaction.amount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            foregroundColor: color,
            child: const Icon(Icons.event_repeat_rounded),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '$amount • ${context.tr(LanguageKeys.dueEveryMonth, {'day': '${transaction.dayOfMonth}'})}',
                  style: const TextStyle(color: Color(0xFF66736C)),
                ),
                const SizedBox(height: 6),
                Text(
                  difference == 0
                      ? context.tr(LanguageKeys.dueToday)
                      : context.tr(LanguageKeys.dueInDays, {
                          'count': '$difference',
                        }),
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Switch(value: transaction.isActive, onChanged: onToggle),
          PopupMenuButton<String>(
            onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Text(context.tr(LanguageKeys.edit)),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(context.tr(LanguageKeys.delete)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecurringTransactionForm extends StatefulWidget {
  final RecurringTransaction? transaction;

  const _RecurringTransactionForm({this.transaction});

  @override
  State<_RecurringTransactionForm> createState() =>
      _RecurringTransactionFormState();
}

class _RecurringTransactionFormState extends State<_RecurringTransactionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late FinanceTransactionType _type;
  late String _category;
  late int _day;
  late int _reminder;

  static const _expenseCategories = [
    LanguageKeys.housing,
    LanguageKeys.needs,
    LanguageKeys.transportation,
    LanguageKeys.bills,
    LanguageKeys.other,
  ];

  @override
  void initState() {
    super.initState();
    final value = widget.transaction;
    _titleController = TextEditingController(text: value?.title);
    _amountController = TextEditingController(
      text: value == null ? '' : formatRupiahInput(value.amount),
    );
    _noteController = TextEditingController(text: value?.note);
    _type = value?.type ?? FinanceTransactionType.expense;
    _category = value?.categoryKey ?? LanguageKeys.bills;
    _day = value?.dayOfMonth ?? DateTime.now().day;
    _reminder = value?.reminderDaysBefore ?? 1;
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr(
                  widget.transaction == null
                      ? LanguageKeys.addRecurringTransaction
                      : LanguageKeys.editRecurringTransaction,
                ),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),
              SegmentedButton<FinanceTransactionType>(
                segments: [
                  ButtonSegment(
                    value: FinanceTransactionType.expense,
                    label: Text(context.tr(LanguageKeys.expense)),
                  ),
                  ButtonSegment(
                    value: FinanceTransactionType.income,
                    label: Text(context.tr(LanguageKeys.income)),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (values) => setState(() {
                  _type = values.first;
                  if (_type == FinanceTransactionType.income) {
                    _category = LanguageKeys.salary;
                  } else if (!_expenseCategories.contains(_category)) {
                    _category = LanguageKeys.bills;
                  }
                }),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: context.tr(LanguageKeys.transactionName),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? context.tr(LanguageKeys.transactionNameRequired)
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: const [RupiahInputFormatter()],
                decoration: InputDecoration(
                  labelText: context.tr(LanguageKeys.amount),
                  prefixText: 'Rp ',
                ),
                validator: (value) {
                  final parsed = parseRupiah(value ?? '');
                  return parsed == null || parsed <= 0
                      ? context.tr(LanguageKeys.amountInvalid)
                      : null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: context.tr(LanguageKeys.category),
                ),
                items:
                    (_type == FinanceTransactionType.income
                            ? [LanguageKeys.salary, LanguageKeys.other]
                            : _expenseCategories)
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(
                              context.tr(value),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (value) => _category = value ?? _category,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _day,
                decoration: InputDecoration(
                  labelText: context.tr(LanguageKeys.dueDate),
                ),
                items: List.generate(
                  31,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text('${index + 1}'),
                  ),
                ),
                onChanged: (value) => _day = value ?? _day,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _reminder,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: context.tr(LanguageKeys.reminder),
                ),
                items: [0, 1, 3, 7]
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(
                          context.tr(LanguageKeys.reminderDaysBefore, {
                            'count': '$value',
                          }),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => _reminder = value ?? _reminder,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: context.tr(LanguageKeys.noteOptional),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _save,
                child: Text(context.tr(LanguageKeys.saveTransaction)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final amount = parseRupiah(_amountController.text)!;
    Navigator.pop(
      context,
      RecurringTransaction(
        id: widget.transaction?.id ?? '',
        title: _titleController.text.trim(),
        amount: amount,
        type: _type,
        categoryKey: _category,
        dayOfMonth: _day,
        reminderDaysBefore: _reminder,
        isActive: widget.transaction?.isActive ?? true,
        note: _noteController.text.trim(),
      ),
    );
  }
}
