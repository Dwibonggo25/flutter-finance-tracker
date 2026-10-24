import 'dart:async';

import 'package:finance_project/features/budgets/domain/entities/monthly_budget.dart';
import 'package:finance_project/features/budgets/domain/repositories/budget_repository.dart';
import 'package:finance_project/features/budgets/presentation/bloc/budget_bloc.dart';
import 'package:finance_project/features/budgets/presentation/bloc/budget_event.dart';
import 'package:finance_project/features/budgets/presentation/bloc/budget_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BudgetBloc', () {
    test('loads the selected monthly budget', () async {
      final repository = _FakeBudgetRepository();
      final bloc = BudgetBloc(repository, initialMonth: DateTime(2026, 10, 25));
      const budget = MonthlyBudget(
        year: 2026,
        month: 10,
        categoryLimits: {'housing': 2000000},
      );

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<BudgetState>().having(
            (state) => state.status,
            'status',
            BudgetStatus.loading,
          ),
          isA<BudgetState>()
              .having((state) => state.status, 'status', BudgetStatus.loaded)
              .having((state) => state.budget, 'budget', same(budget)),
        ]),
      );

      bloc.add(const BudgetStarted());
      await Future<void>.delayed(Duration.zero);
      repository.addBudget(DateTime(2026, 10), budget);

      await expectation;
      expect(repository.watchedMonths, [DateTime(2026, 10)]);
      await bloc.close();
      await repository.close();
    });

    test('saves a monthly budget through the repository', () async {
      final repository = _FakeBudgetRepository();
      final bloc = BudgetBloc(repository, initialMonth: DateTime(2026, 10));
      const budget = MonthlyBudget(
        year: 2026,
        month: 10,
        categoryLimits: {'needs': 750000},
      );

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<BudgetState>().having(
            (state) => state.status,
            'status',
            BudgetStatus.saving,
          ),
          isA<BudgetState>()
              .having(
                (state) => state.status,
                'status',
                BudgetStatus.saveSuccess,
              )
              .having((state) => state.budget, 'budget', same(budget)),
        ]),
      );

      bloc.add(const BudgetSaveRequested(budget));

      await expectation;
      expect(repository.savedBudgets, [budget]);
      await bloc.close();
      await repository.close();
    });
  });
}

class _FakeBudgetRepository implements BudgetRepository {
  final Map<String, StreamController<MonthlyBudget>> _controllers = {};
  final List<DateTime> watchedMonths = [];
  final List<MonthlyBudget> savedBudgets = [];

  @override
  Stream<MonthlyBudget> watchMonthlyBudget(DateTime month) {
    final normalized = DateTime(month.year, month.month);
    watchedMonths.add(normalized);
    return _controllerFor(normalized).stream;
  }

  @override
  Future<void> saveMonthlyBudget(MonthlyBudget budget) async {
    savedBudgets.add(budget);
  }

  void addBudget(DateTime month, MonthlyBudget budget) {
    _controllerFor(month).add(budget);
  }

  StreamController<MonthlyBudget> _controllerFor(DateTime month) {
    final key = '${month.year}-${month.month}';
    return _controllers.putIfAbsent(
      key,
      StreamController<MonthlyBudget>.broadcast,
    );
  }

  Future<void> close() async {
    for (final controller in _controllers.values) {
      await controller.close();
    }
  }
}
