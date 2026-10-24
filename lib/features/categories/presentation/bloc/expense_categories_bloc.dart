import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../libraries/core/localization/language_keys.dart';
import '../../domain/entities/expense_category.dart';
import '../../domain/repositories/expense_category_repository.dart';
import 'expense_categories_event.dart';
import 'expense_categories_state.dart';

class ExpenseCategoriesBloc
    extends Bloc<ExpenseCategoriesEvent, ExpenseCategoriesState> {
  final ExpenseCategoryRepository _repository;
  StreamSubscription<List<ExpenseCategory>>? _categoriesSubscription;

  ExpenseCategoriesBloc(this._repository)
    : super(const ExpenseCategoriesState()) {
    on<ExpenseCategoriesStarted>(_onStarted);
    on<ExpenseCategoriesUpdated>(_onUpdated);
    on<ExpenseCategoriesSubscriptionFailed>(_onSubscriptionFailed);
    on<ExpenseCategoryAddRequested>(_onAddRequested);
    on<ExpenseCategoryRenameRequested>(_onRenameRequested);
    on<ExpenseCategoryDeleteRequested>(_onDeleteRequested);
  }

  Future<void> _onStarted(
    ExpenseCategoriesStarted event,
    Emitter<ExpenseCategoriesState> emit,
  ) async {
    emit(
      state.copyWith(status: ExpenseCategoriesStatus.loading, clearError: true),
    );
    await _categoriesSubscription?.cancel();
    try {
      _categoriesSubscription = _repository.watchCategories().listen(
        (categories) => add(ExpenseCategoriesUpdated(categories)),
        onError: (_, __) => add(const ExpenseCategoriesSubscriptionFailed()),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ExpenseCategoriesStatus.failure,
          errorKey: LanguageKeys.categoryLoadFailed,
        ),
      );
    }
  }

  void _onUpdated(
    ExpenseCategoriesUpdated event,
    Emitter<ExpenseCategoriesState> emit,
  ) {
    emit(
      state.copyWith(
        status: ExpenseCategoriesStatus.loaded,
        categories: event.categories,
        clearError: true,
      ),
    );
  }

  void _onSubscriptionFailed(
    ExpenseCategoriesSubscriptionFailed event,
    Emitter<ExpenseCategoriesState> emit,
  ) {
    emit(
      state.copyWith(
        status: ExpenseCategoriesStatus.failure,
        errorKey: LanguageKeys.categoryLoadFailed,
      ),
    );
  }

  Future<void> _onAddRequested(
    ExpenseCategoryAddRequested event,
    Emitter<ExpenseCategoriesState> emit,
  ) => _runMutation(
    emit,
    action: () => _repository.addCategory(event.name),
    errorKey: LanguageKeys.categorySaveFailed,
  );

  Future<void> _onRenameRequested(
    ExpenseCategoryRenameRequested event,
    Emitter<ExpenseCategoriesState> emit,
  ) => _runMutation(
    emit,
    action: () => _repository.renameCategory(event.category, event.newName),
    errorKey: LanguageKeys.categorySaveFailed,
  );

  Future<void> _onDeleteRequested(
    ExpenseCategoryDeleteRequested event,
    Emitter<ExpenseCategoriesState> emit,
  ) => _runMutation(
    emit,
    action: () => _repository.deleteCategory(event.categoryId),
    errorKey: LanguageKeys.categoryDeleteFailed,
  );

  Future<void> _runMutation(
    Emitter<ExpenseCategoriesState> emit, {
    required Future<void> Function() action,
    required String errorKey,
  }) async {
    emit(
      state.copyWith(
        status: ExpenseCategoriesStatus.submitting,
        clearError: true,
      ),
    );
    try {
      await action();
      emit(
        state.copyWith(
          status: ExpenseCategoriesStatus.loaded,
          clearError: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ExpenseCategoriesStatus.failure,
          errorKey: errorKey,
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _categoriesSubscription?.cancel();
    return super.close();
  }
}
