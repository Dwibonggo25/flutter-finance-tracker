import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../libraries/core/localization/language_keys.dart';
import '../../domain/entities/monthly_budget.dart';
import '../../domain/repositories/budget_repository.dart';
import 'budget_event.dart';
import 'budget_state.dart';

class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  final BudgetRepository _repository;
  StreamSubscription<MonthlyBudget>? _budgetSubscription;

  BudgetBloc(this._repository, {DateTime? initialMonth})
    : super(BudgetState.initial(initialMonth ?? DateTime.now())) {
    on<BudgetStarted>(_onStarted);
    on<BudgetMonthChanged>(_onMonthChanged);
    on<BudgetUpdated>(_onUpdated);
    on<BudgetSubscriptionFailed>(_onSubscriptionFailed);
    on<BudgetSaveRequested>(_onSaveRequested);
  }

  Future<void> _onStarted(BudgetStarted event, Emitter<BudgetState> emit) =>
      _watchMonth(state.selectedMonth, emit);

  Future<void> _onMonthChanged(
    BudgetMonthChanged event,
    Emitter<BudgetState> emit,
  ) => _watchMonth(event.month, emit);

  Future<void> _watchMonth(DateTime month, Emitter<BudgetState> emit) async {
    final selectedMonth = DateTime(month.year, month.month);
    emit(
      state.copyWith(
        status: BudgetStatus.loading,
        selectedMonth: selectedMonth,
        budget: MonthlyBudget(
          year: selectedMonth.year,
          month: selectedMonth.month,
        ),
        clearError: true,
      ),
    );
    await _budgetSubscription?.cancel();
    try {
      _budgetSubscription = _repository
          .watchMonthlyBudget(selectedMonth)
          .listen(
            (budget) => add(BudgetUpdated(budget)),
            onError: (_, __) => add(const BudgetSubscriptionFailed()),
          );
    } catch (_) {
      emit(
        state.copyWith(
          status: BudgetStatus.failure,
          errorKey: LanguageKeys.budgetLoadFailed,
        ),
      );
    }
  }

  void _onUpdated(BudgetUpdated event, Emitter<BudgetState> emit) {
    emit(
      state.copyWith(
        status: BudgetStatus.loaded,
        budget: event.budget,
        clearError: true,
      ),
    );
  }

  void _onSubscriptionFailed(
    BudgetSubscriptionFailed event,
    Emitter<BudgetState> emit,
  ) {
    emit(
      state.copyWith(
        status: BudgetStatus.failure,
        errorKey: LanguageKeys.budgetLoadFailed,
      ),
    );
  }

  Future<void> _onSaveRequested(
    BudgetSaveRequested event,
    Emitter<BudgetState> emit,
  ) async {
    emit(state.copyWith(status: BudgetStatus.saving, clearError: true));
    try {
      await _repository.saveMonthlyBudget(event.budget);
      emit(
        state.copyWith(
          status: BudgetStatus.saveSuccess,
          budget: event.budget,
          clearError: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: BudgetStatus.failure,
          errorKey: LanguageKeys.budgetSaveFailed,
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _budgetSubscription?.cancel();
    return super.close();
  }
}
