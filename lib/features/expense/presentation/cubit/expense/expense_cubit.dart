import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/expense_entity.dart';
import '../../../domain/repositories/expense_repository.dart';
import 'expense_state.dart';

class ExpenseCubit extends Cubit<ExpenseState> {
  final ExpenseRepository _expenseRepository;

  ExpenseCubit(this._expenseRepository) : super(const ExpenseInitial());

  Future<void> loadExpenses() async {
    emit(const ExpenseLoading());
    try {
      await _reloadExpenses();
    } catch (error) {
      emit(ExpenseError(error.toString()));
    }
  }

  Future<void> getExpenseById(int id) async {
    emit(const ExpenseLoading());
    try {
      final expense = await _expenseRepository.getExpenseById(id);
      _emitSingleExpense(expense);
    } catch (error) {
      emit(ExpenseError(error.toString()));
    }
  }

  Future<void> createExpense(ExpenseEntity expense) async {
    emit(const ExpenseLoading());
    try {
      await _expenseRepository.createExpense(expense);
      await _reloadExpenses();
    } catch (error) {
      emit(ExpenseError(error.toString()));
    }
  }

  Future<void> updateExpense(ExpenseEntity expense) async {
    emit(const ExpenseLoading());
    try {
      await _expenseRepository.updateExpense(expense);
      await _reloadExpenses();
    } catch (error) {
      emit(ExpenseError(error.toString()));
    }
  }

  Future<void> deleteExpense(int id) async {
    emit(const ExpenseLoading());
    try {
      await _expenseRepository.deleteExpense(id);
      await _reloadExpenses();
    } catch (error) {
      emit(ExpenseError(error.toString()));
    }
  }

  Future<void> _reloadExpenses() async {
    final expenses = await _expenseRepository.getAllExpenses();
    _emitExpenses(expenses);
  }

  void _emitSingleExpense(ExpenseEntity? expense) {
    if (expense == null) {
      emit(const ExpenseEmpty());
      return;
    }
    emit(ExpenseLoaded(<ExpenseEntity>[expense]));
  }

  void _emitExpenses(List<ExpenseEntity> expenses) {
    if (expenses.isEmpty) {
      emit(const ExpenseEmpty());
      return;
    }
    emit(ExpenseLoaded(expenses));
  }
}
