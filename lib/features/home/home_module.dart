import 'package:finance_project/features/home/presentation/ui/home_page.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../budgets/data/repositories/firestore_budget_repository.dart';
import '../budgets/domain/repositories/budget_repository.dart';
import '../categories/data/repositories/firestore_expense_category_repository.dart';
import '../categories/domain/repositories/expense_category_repository.dart';
import '../help/data/repositories/openai_help_repository.dart';
import '../help/domain/repositories/ai_help_repository.dart';
import '../recurring_transactions/data/repositories/firestore_recurring_transaction_repository.dart';
import '../recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import '../profile/data/repositories/firebase_profile_repository.dart';
import '../profile/domain/repositories/profile_repository.dart';
import '../transactions/data/repositories/firestore_transaction_repository.dart';
import '../transactions/domain/repositories/transaction_repository.dart';

class HomeModule extends Module {
  @override
  List<Bind> get binds => [
    Bind.lazySingleton<BudgetRepository>((i) => FirestoreBudgetRepository()),
    Bind.lazySingleton<ExpenseCategoryRepository>(
      (i) => FirestoreExpenseCategoryRepository(),
    ),
    Bind.lazySingleton<AiHelpRepository>((i) => OpenAiHelpRepository()),
    Bind.lazySingleton<RecurringTransactionRepository>(
      (i) => FirestoreRecurringTransactionRepository(),
    ),
    Bind.lazySingleton<ProfileRepository>((i) => FirebaseProfileRepository()),
    Bind.lazySingleton<TransactionRepository>(
      (i) => FirestoreTransactionRepository(),
    ),
  ];

  @override
  List<ModularRoute> get routes => [
    ChildRoute('/', child: (_, __) => const HomePage()),
  ];
}
