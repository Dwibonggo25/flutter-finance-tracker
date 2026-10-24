import 'dart:async';
import 'dart:math' as math;

import 'package:finance_project/features/home/presentation/ui/transaction_form_sheet.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';

import '../../../../libraries/core/localization/app_localizations.dart';
import '../../../../libraries/core/localization/language_controller.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../../../libraries/core/notifications/local_notification_service.dart';
import '../../../../libraries/core/theme/app_colors.dart';
import '../../../../libraries/core/theme/app_theme_context.dart';
import '../../../../libraries/core/theme/theme_controller.dart';
import '../../../budgets/domain/repositories/budget_repository.dart';
import '../../../categories/domain/entities/expense_category.dart';
import '../../../categories/domain/repositories/expense_category_repository.dart';
import '../../../help/domain/repositories/ai_help_repository.dart';
import '../../../help/presentation/ui/help_page.dart';
import '../../../recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import '../../../recurring_transactions/presentation/ui/recurring_transactions_page.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../profile/presentation/ui/profile_page.dart';
import '../../../transactions/domain/entities/finance_transaction.dart';
import '../../../transactions/domain/extensions/finance_transaction_iterable_extension.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';
import 'budget_tab.dart';
import 'qris_page.dart';
import 'reports_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Keep the implementation available while the paid AI backend is disabled.
  static const _showAiHelp = bool.fromEnvironment('ENABLE_AI_HELP');

  int _selectedIndex = 0;
  late final TransactionRepository _transactionRepository;
  late final BudgetRepository _budgetRepository;
  late final RecurringTransactionRepository _recurringRepository;
  late final ProfileRepository _profileRepository;
  late final ExpenseCategoryRepository _categoryRepository;
  late final AiHelpRepository _aiHelpRepository;
  late Stream<List<FinanceTransaction>> _transactionsStream;
  late Stream<List<ExpenseCategory>> _categoriesStream;
  List<ExpenseCategory> _currentCategories = ExpenseCategory.defaults;

  static const _titleKeys = [
    LanguageKeys.summary,
    LanguageKeys.transactions,
    LanguageKeys.budget,
    LanguageKeys.reports,
  ];

  @override
  void initState() {
    super.initState();
    _transactionRepository = Modular.get<TransactionRepository>();
    _budgetRepository = Modular.get<BudgetRepository>();
    _recurringRepository = Modular.get<RecurringTransactionRepository>();
    _profileRepository = Modular.get<ProfileRepository>();
    _categoryRepository = Modular.get<ExpenseCategoryRepository>();
    _aiHelpRepository = Modular.get<AiHelpRepository>();
    _transactionsStream = _transactionRepository.watchTransactions();
    _categoriesStream = _categoryRepository.watchCategories();
    unawaited(_ensureDefaultCategories());
  }

  Future<void> _ensureDefaultCategories() async {
    try {
      await _categoryRepository.ensureDefaultCategories();
    } on FirebaseException catch (error) {
      debugPrint(
        'Unable to initialize expense categories (${error.code}). '
        'Make sure the latest Firestore rules are deployed.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ExpenseCategory>>(
      stream: _categoriesStream,
      builder: (context, categorySnapshot) {
        final categories = categorySnapshot.data?.isNotEmpty == true
            ? categorySnapshot.data!
            : ExpenseCategory.defaults;
        _currentCategories = categories;
        return StreamBuilder<List<FinanceTransaction>>(
          stream: _transactionsStream,
          builder: (context, snapshot) {
            final transactions = snapshot.data ?? const <FinanceTransaction>[];
            final pages = [
              _DashboardTab(
                transactions: transactions,
                categories: categories,
                onSeeAll: () => setState(() => _selectedIndex = 1),
                onViewCashFlow: () => setState(() => _selectedIndex = 3),
                onAdd: _addTransaction,
              ),
              _TransactionsTab(
                transactions: transactions,
                categories: categories,
                onAdd: _addTransaction,
                onEdit: _editTransaction,
                onDelete: _deleteTransaction,
              ),
              BudgetTab(
                transactions: transactions,
                categories: categories,
                budgetRepository: _budgetRepository,
                categoryRepository: _categoryRepository,
              ),
              ReportsTab(
                transactions: transactions,
                categories: categories,
                isActive: _selectedIndex == 3,
              ),
            ];

            final Widget body;
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              body = const _TransactionsLoadingState();
            } else if (snapshot.hasError && !snapshot.hasData) {
              body = _TransactionsErrorState(onRetry: _retryTransactions);
            } else {
              body = IndexedStack(index: _selectedIndex, children: pages);
            }

            return Scaffold(
              appBar: AppBar(
                surfaceTintColor: Colors.transparent,
                titleSpacing: 20,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(_titleKeys[_selectedIndex]),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (_selectedIndex == 0)
                      Text(
                        MaterialLocalizations.of(
                          context,
                        ).formatFullDate(DateTime.now()),
                        style: const TextStyle(
                          color: Color(0xFF718078),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                  ],
                ),
                actions: [
                  if (_selectedIndex == 1)
                    IconButton(
                      onPressed: _addTransaction,
                      tooltip: context.tr(LanguageKeys.addTransaction),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                    ),
                  IconButton(
                    onPressed: _openRecurringTransactions,
                    tooltip: context.tr(LanguageKeys.notifications),
                    icon: const Badge(
                      smallSize: 7,
                      child: Icon(Icons.notifications_none_rounded),
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: context.tr(LanguageKeys.account),
                    offset: const Offset(0, 48),
                    onSelected: (value) {
                      if (value == 'logout') {
                        _logout();
                      } else if (value == 'profile') {
                        _openProfile();
                      } else if (value == 'help') {
                        _openHelp();
                      } else if (value == 'theme_light') {
                        ThemeController.instance.changeTheme(ThemeMode.light);
                      } else if (value == 'theme_dark') {
                        ThemeController.instance.changeTheme(ThemeMode.dark);
                      } else if (value == 'language_id') {
                        LanguageController.instance.changeLanguage('id');
                      } else if (value == 'language_en') {
                        LanguageController.instance.changeLanguage('en');
                      }
                    },
                    itemBuilder: (menuContext) => [
                      PopupMenuItem(
                        value: 'profile',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.person_outline_rounded),
                          title: Text(menuContext.tr(LanguageKeys.profile)),
                        ),
                      ),
                      if (_showAiHelp)
                        PopupMenuItem(
                          value: 'help',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.auto_awesome_rounded),
                            title: Text(menuContext.tr(LanguageKeys.help)),
                          ),
                        ),
                      PopupMenuItem(
                        value: 'language_id',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.language_rounded),
                          title: Text(menuContext.tr(LanguageKeys.indonesian)),
                          trailing:
                              LanguageController.instance.value.languageCode ==
                                  'id'
                              ? const Icon(Icons.check_rounded)
                              : null,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'language_en',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.language_rounded),
                          title: Text(menuContext.tr(LanguageKeys.english)),
                          trailing:
                              LanguageController.instance.value.languageCode ==
                                  'en'
                              ? const Icon(Icons.check_rounded)
                              : null,
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'theme_light',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.light_mode_outlined),
                          title: Text(menuContext.tr(LanguageKeys.lightMode)),
                          trailing:
                              ThemeController.instance.value == ThemeMode.light
                              ? const Icon(Icons.check_rounded)
                              : null,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'theme_dark',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.dark_mode_outlined),
                          title: Text(menuContext.tr(LanguageKeys.darkMode)),
                          trailing:
                              ThemeController.instance.value == ThemeMode.dark
                              ? const Icon(Icons.check_rounded)
                              : null,
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'logout',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.logout_rounded),
                          title: Text(menuContext.tr(LanguageKeys.logout)),
                        ),
                      ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.only(right: 18),
                      child: CircleAvatar(
                        radius: 19,
                        backgroundColor: AppColors.primaryContainer,
                        backgroundImage:
                            FirebaseAuth.instance.currentUser?.photoURL == null
                            ? null
                            : NetworkImage(
                                FirebaseAuth.instance.currentUser!.photoURL!,
                              ),
                        child:
                            FirebaseAuth.instance.currentUser?.photoURL == null
                            ? Text(
                                _profileInitial,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              body: body,
              floatingActionButton: FloatingActionButton(
                onPressed: _openQris,
                tooltip: context.tr(LanguageKeys.qris),
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.white,
                elevation: 5,
                shape: const CircleBorder(
                  side: BorderSide(color: Colors.white, width: 4),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_2_rounded, size: 25),
                    Text(
                      'QRIS',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerDocked,
              bottomNavigationBar: BottomAppBar(
                height: 80,
                padding: EdgeInsets.zero,
                color: AppColors.primary,
                surfaceTintColor: Colors.transparent,
                shape: const AutomaticNotchedShape(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  CircleBorder(),
                ),
                notchMargin: 7,
                child: Row(
                  children: [
                    _NavButton(
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home_rounded,
                      label: context.tr(LanguageKeys.home),
                      selected: _selectedIndex == 0,
                      onTap: () => _selectTab(0),
                    ),
                    _NavButton(
                      icon: Icons.receipt_long_outlined,
                      selectedIcon: Icons.receipt_long_rounded,
                      label: context.tr(LanguageKeys.transactions),
                      selected: _selectedIndex == 1,
                      onTap: () => _selectTab(1),
                    ),
                    const SizedBox(width: 68),
                    _NavButton(
                      icon: Icons.show_chart_rounded,
                      selectedIcon: Icons.area_chart_rounded,
                      label: context.tr(LanguageKeys.budget),
                      selected: _selectedIndex == 2,
                      onTap: () => _selectTab(2),
                    ),
                    _NavButton(
                      icon: Icons.bar_chart_outlined,
                      selectedIcon: Icons.bar_chart_rounded,
                      label: context.tr(LanguageKeys.reports),
                      selected: _selectedIndex == 3,
                      onTap: () => _selectTab(3),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openRecurringTransactions() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RecurringTransactionsPage(
          repository: _recurringRepository,
          notificationService: LocalNotificationService.instance,
        ),
      ),
    );
  }

  String get _profileInitial {
    final user = FirebaseAuth.instance.currentUser;
    final value = user?.displayName?.trim();
    if (value != null && value.isNotEmpty) return value[0].toUpperCase();
    final email = user?.email?.trim();
    return email != null && email.isNotEmpty ? email[0].toUpperCase() : 'U';
  }

  Future<void> _openProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProfilePage(repository: _profileRepository),
      ),
    );
    if (mounted) setState(() {});
  }

  void _openHelp() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HelpPage(repository: _aiHelpRepository),
      ),
    );
  }

  void _selectTab(int index) => setState(() => _selectedIndex = index);

  void _retryTransactions() {
    setState(() {
      _transactionsStream = _transactionRepository.watchTransactions();
    });
  }

  Future<void> _addTransaction() => _openTransactionForm();

  Future<void> _editTransaction(FinanceTransaction transaction) {
    return _openTransactionForm(initialTransaction: transaction);
  }

  Future<void> _openTransactionForm({
    FinanceTransaction? initialTransaction,
  }) async {
    final transaction = await showModalBottomSheet<FinanceTransaction>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionFormSheet(
        initialTransaction: initialTransaction,
        categories: _currentCategories,
      ),
    );
    if (transaction == null || !mounted) return;

    try {
      if (initialTransaction == null) {
        await _transactionRepository.createTransaction(transaction);
      } else {
        await _transactionRepository.updateTransaction(transaction);
      }
      if (!mounted) return;
      _showMessage(
        initialTransaction == null
            ? LanguageKeys.transactionCreated
            : LanguageKeys.transactionUpdated,
      );
    } catch (_) {
      if (mounted) _showMessage(LanguageKeys.transactionSaveFailed);
    }
  }

  Future<void> _deleteTransaction(FinanceTransaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr(LanguageKeys.deleteTransaction)),
        content: Text(
          dialogContext.tr(LanguageKeys.deleteTransactionConfirmation, {
            'title': transaction.title,
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.tr(LanguageKeys.cancel)),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.tr(LanguageKeys.delete)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _transactionRepository.deleteTransaction(transaction.id);
      if (mounted) _showMessage(LanguageKeys.transactionDeleted);
    } catch (_) {
      if (mounted) _showMessage(LanguageKeys.transactionDeleteFailed);
    }
  }

  void _showMessage(String key) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr(key)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openQris() {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const QrisPage()));
  }

  Future<void> _logout() async {
    if (Firebase.apps.isNotEmpty) await FirebaseAuth.instance.signOut();
    Modular.to.navigate('/auth/');
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Colors.white;
    const inactiveColor = Color(0xFFBDE7F5);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Semantics(
          selected: selected,
          button: true,
          label: label,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 34,
                height: 31,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  selected ? selectedIcon : icon,
                  color: selected ? activeColor : inactiveColor,
                  size: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: selected ? activeColor : inactiveColor,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionsLoadingState extends StatelessWidget {
  const _TransactionsLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _TransactionsErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _TransactionsErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: Color(0xFFC7612C),
              size: 48,
            ),
            const SizedBox(height: 14),
            Text(
              context.tr(LanguageKeys.transactionsLoadFailed),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, height: 1.4),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.tr(LanguageKeys.retry)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final List<FinanceTransaction> transactions;
  final List<ExpenseCategory> categories;
  final VoidCallback onSeeAll;
  final VoidCallback onViewCashFlow;
  final VoidCallback onAdd;

  const _DashboardTab({
    required this.transactions,
    required this.categories,
    required this.onSeeAll,
    required this.onViewCashFlow,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final income = transactions.totalIncome;
    final expense = transactions.totalExpense;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 112),
      children: [
        Text(
          context.tr(LanguageKeys.greeting),
          style: const TextStyle(color: Color(0xFF66736C), fontSize: 15),
        ),
        const SizedBox(height: 14),
        _BalanceCard(
          balance: income - expense,
          income: income,
          expense: expense,
        ),
        const SizedBox(height: 24),
        _SectionTitle(title: context.tr(LanguageKeys.financialNotes)),
        const SizedBox(height: 12),
        _FinancialNotesCarousel(
          transactions: transactions,
          onViewCashFlow: onViewCashFlow,
        ),
        const SizedBox(height: 24),
        _SectionTitle(
          title: context.tr(LanguageKeys.recentTransactions),
          action: context.tr(LanguageKeys.seeAll),
          onTap: onSeeAll,
        ),
        const SizedBox(height: 8),
        if (transactions.isEmpty)
          _EmptyTransactionsCard(onAdd: onAdd)
        else
          ...transactions
              .take(4)
              .map(
                (transaction) =>
                    _TransactionTile(transaction, categories: categories),
              ),
      ],
    );
  }
}

class _EmptyTransactionsCard extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyTransactionsCard({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_rounded,
            color: AppColors.primary,
            size: 38,
          ),
          const SizedBox(height: 12),
          Text(
            context.tr(LanguageKeys.noTransactions),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr(LanguageKeys.noTransactionsDescription),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF718078), height: 1.4),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: Text(context.tr(LanguageKeys.addTransaction)),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatefulWidget {
  final double balance;
  final double income;
  final double expense;

  const _BalanceCard({
    required this.balance,
    required this.income,
    required this.expense,
  });

  @override
  State<_BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<_BalanceCard> {
  bool _showAmount = true;

  @override
  Widget build(BuildContext context) {
    final visibilityLabel = context.tr(
      _showAmount ? LanguageKeys.hideAmount : LanguageKeys.showAmount,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: AppColors.primaryShadow,
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr(LanguageKeys.totalBalance),
                  style: const TextStyle(
                    color: Color(0xFFC9EDFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              Tooltip(
                message: visibilityLabel,
                child: IconButton(
                  onPressed: () => setState(() => _showAmount = !_showAmount),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 38,
                    height: 38,
                  ),
                  icon: Icon(
                    _showAmount
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Semantics(
            label: context.tr(LanguageKeys.totalBalance),
            value: _showAmount
                ? _formatCurrency(widget.balance)
                : visibilityLabel,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                _showAmount ? _formatCurrency(widget.balance) : 'Rp ••••••••',
                key: ValueKey(_showAmount),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 31,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _BalanceMetric(
                  icon: Icons.south_west_rounded,
                  label: context.tr(LanguageKeys.income),
                  amount: widget.income,
                  showAmount: _showAmount,
                  color: const Color(0xFF9DE4BE),
                ),
              ),
              Container(
                width: 1,
                height: 42,
                color: Colors.white.withValues(alpha: 0.18),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _BalanceMetric(
                  icon: Icons.north_east_rounded,
                  label: context.tr(LanguageKeys.expense),
                  amount: widget.expense,
                  showAmount: _showAmount,
                  color: const Color(0xFFFFC4AE),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final double amount;
  final bool showAmount;
  final Color color;

  const _BalanceMetric({
    required this.icon,
    required this.label,
    required this.amount,
    required this.showAmount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.68),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  showAmount ? _formatCompactCurrency(amount) : 'Rp ••••',
                  key: ValueKey(showAmount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FinancialNotesCarousel extends StatefulWidget {
  final List<FinanceTransaction> transactions;
  final VoidCallback onViewCashFlow;

  const _FinancialNotesCarousel({
    required this.transactions,
    required this.onViewCashFlow,
  });

  @override
  State<_FinancialNotesCarousel> createState() =>
      _FinancialNotesCarouselState();
}

class _FinancialNotesCarouselState extends State<_FinancialNotesCarousel> {
  final PageController _pageController = PageController();
  late DateTime _latestMonth;
  late DateTime _selectedMonth;
  int _currentPage = 0;
  bool _showAmount = true;

  @override
  void initState() {
    super.initState();
    final referenceDate = widget.transactions.isEmpty
        ? DateTime.now()
        : widget.transactions
              .map((transaction) => transaction.date)
              .reduce((left, right) => left.isAfter(right) ? left : right);
    _latestMonth = DateTime(referenceDate.year, referenceDate.month);
    _selectedMonth = _latestMonth;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedTransactions = widget.transactions.where(
      (transaction) =>
          transaction.date.year == _selectedMonth.year &&
          transaction.date.month == _selectedMonth.month,
    );
    final transactions = selectedTransactions.toList();
    final income = transactions.totalIncome;
    final expense = transactions.totalExpense;
    final cashFlow = income - expense;
    final expenseSegments = transactions
        .where(
          (transaction) => transaction.type == FinanceTransactionType.expense,
        )
        .map((transaction) => transaction.amount)
        .toList();

    final slides = [
      _FinanceRingSlide(
        title: context.tr(LanguageKeys.totalExpense),
        amount: expense,
        showAmount: _showAmount,
        icon: Icons.north_east_rounded,
        colors: const [
          Color(0xFF7B47B4),
          Color(0xFFD05D67),
          Color(0xFFB69A36),
          Color(0xFF31A4B5),
        ],
        values: expenseSegments,
        onToggleAmount: _toggleAmount,
      ),
      _FinanceRingSlide(
        title: context.tr(LanguageKeys.totalIncome),
        amount: income,
        showAmount: _showAmount,
        icon: Icons.south_west_rounded,
        colors: const [Color(0xFFFFA000)],
        values: [income],
        onToggleAmount: _toggleAmount,
      ),
      _FinanceRingSlide(
        title: context.tr(LanguageKeys.cashFlow),
        amount: cashFlow,
        showAmount: _showAmount,
        icon: Icons.swap_vert_rounded,
        colors: const [Color(0xFF258A63), Color(0xFF7B47B4)],
        values: [income, expense],
        onToggleAmount: _toggleAmount,
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: context.borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1415261F),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<DateTime>(
                    value: _selectedMonth,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(18),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primary,
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    items: _availableMonths
                        .map(
                          (month) => DropdownMenuItem(
                            value: month,
                            child: Text(_formatMonth(context, month)),
                          ),
                        )
                        .toList(),
                    onChanged: (month) {
                      if (month != null) {
                        setState(() => _selectedMonth = month);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  context.tr(LanguageKeys.cashFlow),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: slides,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CarouselArrow(
                icon: Icons.chevron_left_rounded,
                enabled: _currentPage > 0,
                onPressed: () => _goToPage(_currentPage - 1),
              ),
              const SizedBox(width: 20),
              ...List.generate(
                slides.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: index == _currentPage ? 18 : 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: index == _currentPage
                        ? const Color(0xFF173B64)
                        : const Color(0xFFDCE3DF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              _CarouselArrow(
                icon: Icons.chevron_right_rounded,
                enabled: _currentPage < slides.length - 1,
                onPressed: () => _goToPage(_currentPage + 1),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: widget.onViewCashFlow,
            icon: const Icon(Icons.insights_rounded, size: 18),
            label: Text(context.tr(LanguageKeys.viewCashFlowDetails)),
          ),
        ],
      ),
    );
  }

  List<DateTime> get _availableMonths => List.generate(5, (index) {
    final month = _latestMonth.month - index;
    return DateTime(_latestMonth.year, month);
  });

  void _toggleAmount() => setState(() => _showAmount = !_showAmount);

  void _goToPage(int page) {
    if (page < 0 || page > 2) return;
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }
}

class _FinanceRingSlide extends StatelessWidget {
  final String title;
  final double amount;
  final bool showAmount;
  final IconData icon;
  final List<Color> colors;
  final List<double> values;
  final VoidCallback onToggleAmount;

  const _FinanceRingSlide({
    required this.title,
    required this.amount,
    required this.showAmount,
    required this.icon,
    required this.colors,
    required this.values,
    required this.onToggleAmount,
  });

  @override
  Widget build(BuildContext context) {
    final visibilityLabel = context.tr(
      showAmount ? LanguageKeys.hideAmount : LanguageKeys.showAmount,
    );

    return Semantics(
      label: title,
      value: showAmount ? _formatIdr(amount) : visibilityLabel,
      child: Center(
        child: SizedBox.square(
          dimension: 225,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size.square(205),
                painter: _RingChartPainter(values: values, colors: colors),
              ),
              SizedBox(
                width: 142,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF2C3330),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Text(
                        showAmount ? _formatIdr(amount) : 'IDR ••••••••',
                        key: ValueKey(showAmount),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF173B64),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Tooltip(
                      message: visibilityLabel,
                      child: InkWell(
                        onTap: onToggleAmount,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 38,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7F4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFDDE3DF)),
                          ),
                          child: Icon(
                            showAmount
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 19,
                            color: const Color(0xFF66736C),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 3,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE1E6E3)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x18000000), blurRadius: 8),
                    ],
                  ),
                  child: Icon(icon, color: colors.first, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  const _RingChartPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - 20) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const strokeWidth = 18.0;
    const fullCircle = math.pi * 2;
    final backgroundPaint = Paint()
      ..color = const Color(0xFFECEFED)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, backgroundPaint);

    final total = values.fold<double>(0, (sum, value) => sum + value.abs());
    if (total <= 0) return;

    final activeValues = values.where((value) => value.abs() > 0).toList();
    final gap = activeValues.length > 1 ? 0.045 : 0.018;
    final availableSweep = fullCircle - (gap * activeValues.length);
    var startAngle = -math.pi / 2;

    for (var index = 0; index < activeValues.length; index++) {
      final value = activeValues[index];
      final sweep = availableSweep * (value.abs() / total);
      final paint = Paint()
        ..color = colors[index % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _RingChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.colors != colors;
}

class _CarouselArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _CarouselArrow({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? onPressed : null,
      style: IconButton.styleFrom(
        backgroundColor: enabled ? const Color(0xFFF0F4F2) : Colors.transparent,
        foregroundColor: const Color(0xFF173B64),
        disabledForegroundColor: const Color(0xFFC9D0CC),
      ),
      icon: Icon(icon),
    );
  }
}

class _TransactionsTab extends StatefulWidget {
  final List<FinanceTransaction> transactions;
  final List<ExpenseCategory> categories;
  final VoidCallback onAdd;
  final ValueChanged<FinanceTransaction> onEdit;
  final ValueChanged<FinanceTransaction> onDelete;

  const _TransactionsTab({
    required this.transactions,
    required this.categories,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<_TransactionsTab> {
  final _searchController = TextEditingController();
  _TransactionFilter _filter = _TransactionFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactions = _filteredTransactions;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 112),
      children: [
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: context.tr(LanguageKeys.searchTransaction),
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
            filled: true,
            fillColor: context.surfaceColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: context.tr(LanguageKeys.all),
                selected: _filter == _TransactionFilter.all,
                onTap: () => _setFilter(_TransactionFilter.all),
              ),
              _FilterChip(
                label: context.tr(LanguageKeys.income),
                selected: _filter == _TransactionFilter.income,
                onTap: () => _setFilter(_TransactionFilter.income),
              ),
              _FilterChip(
                label: context.tr(LanguageKeys.expense),
                selected: _filter == _TransactionFilter.expense,
                onTap: () => _setFilter(_TransactionFilter.expense),
              ),
              _FilterChip(
                label: context.tr(LanguageKeys.thisMonth),
                selected: _filter == _TransactionFilter.thisMonth,
                onTap: () => _setFilter(_TransactionFilter.thisMonth),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (transactions.isEmpty)
          _EmptyTransactionsCard(onAdd: widget.onAdd)
        else
          ...transactions.map(
            (transaction) => _TransactionTile(
              transaction,
              categories: widget.categories,
              onEdit: () => widget.onEdit(transaction),
              onDelete: () => widget.onDelete(transaction),
            ),
          ),
      ],
    );
  }

  List<FinanceTransaction> get _filteredTransactions {
    final query = _searchController.text.trim().toLowerCase();
    final now = DateTime.now();

    return widget.transactions
        .where((transaction) {
          final matchesQuery =
              query.isEmpty ||
              transaction.title.toLowerCase().contains(query) ||
              transaction.note.toLowerCase().contains(query);
          final matchesFilter = switch (_filter) {
            _TransactionFilter.all => true,
            _TransactionFilter.income =>
              transaction.type == FinanceTransactionType.income,
            _TransactionFilter.expense =>
              transaction.type == FinanceTransactionType.expense,
            _TransactionFilter.thisMonth =>
              transaction.date.year == now.year &&
                  transaction.date.month == now.month,
          };
          return matchesQuery && matchesFilter;
        })
        .toList(growable: false);
  }

  void _setFilter(_TransactionFilter filter) {
    setState(() => _filter = filter);
  }
}

enum _TransactionFilter { all, income, expense, thisMonth }

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.primary : context.surfaceColor,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? AppColors.primary : context.borderColor,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final FinanceTransaction transaction;
  final List<ExpenseCategory> categories;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _TransactionTile(
    this.transaction, {
    required this.categories,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final income = transaction.type == FinanceTransactionType.income;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: income ? const Color(0xFFE1F4EA) : const Color(0xFFFFEEE4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _iconForTransaction(transaction, categories),
              color: income ? const Color(0xFF19704E) : const Color(0xFFC7612C),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_categoryLabel(context, transaction.categoryKey, categories)} • ${MaterialLocalizations.of(context).formatShortMonthDay(transaction.date)}',
                  style: const TextStyle(
                    color: Color(0xFF7A8780),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${income ? '+' : '-'}${_formatCurrency(transaction.amount)}',
                style: TextStyle(
                  color: income
                      ? const Color(0xFF19704E)
                      : const Color(0xFFB54D2B),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (onEdit != null || onDelete != null)
                PopupMenuButton<_TransactionAction>(
                  tooltip: context.tr(LanguageKeys.transactionActions),
                  onSelected: (action) {
                    switch (action) {
                      case _TransactionAction.edit:
                        onEdit?.call();
                      case _TransactionAction.delete:
                        onDelete?.call();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _TransactionAction.edit,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.edit_outlined),
                        title: Text(context.tr(LanguageKeys.edit)),
                      ),
                    ),
                    PopupMenuItem(
                      value: _TransactionAction.delete,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.delete_outline_rounded),
                        title: Text(context.tr(LanguageKeys.delete)),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _TransactionAction { edit, delete }

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onTap;

  const _SectionTitle({required this.title, this.action, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ),
        if (action != null) TextButton(onPressed: onTap, child: Text(action!)),
      ],
    );
  }
}

IconData _iconForTransaction(
  FinanceTransaction transaction,
  List<ExpenseCategory> categories,
) {
  if (transaction.type == FinanceTransactionType.income) {
    return Icons.account_balance_wallet_rounded;
  }
  for (final category in categories) {
    if (category.id == transaction.categoryKey) {
      return _iconForExpenseCategory(category);
    }
  }
  return _iconForCategory(transaction.categoryKey);
}

IconData _iconForCategory(String category) {
  return switch (category) {
    LanguageKeys.housing => Icons.home_rounded,
    LanguageKeys.needs => Icons.shopping_bag_rounded,
    LanguageKeys.transportation => Icons.directions_car_filled_rounded,
    LanguageKeys.bills => Icons.receipt_long_rounded,
    _ => Icons.shopping_cart_rounded,
  };
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

String _formatMonth(BuildContext context, DateTime month) {
  final value = DateFormat(
    'MMMM yyyy',
    Localizations.localeOf(context).toLanguageTag(),
  ).format(month);
  return value.isEmpty
      ? value
      : '${value[0].toUpperCase()}${value.substring(1)}';
}

String _formatIdr(double amount) {
  final value = NumberFormat.decimalPattern('id_ID').format(amount.abs());
  return amount < 0 ? '-IDR $value' : 'IDR $value';
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
