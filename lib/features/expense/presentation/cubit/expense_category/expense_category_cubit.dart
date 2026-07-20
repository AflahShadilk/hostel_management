import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/expense_category_entity.dart';
import '../../../domain/repositories/expense_repository.dart';
import 'expense_category_state.dart';

class ExpenseCategoryCubit extends Cubit<ExpenseCategoryState> {
  final ExpenseRepository _expenseRepository;

  ExpenseCategoryCubit(this._expenseRepository)
      : super(const ExpenseCategoryInitial());

  Future<void> loadCategories() async {
    emit(const ExpenseCategoryLoading());
    try {
      await _reloadCategories();
    } catch (error) {
      emit(ExpenseCategoryError(error.toString()));
    }
  }

  Future<void> getCategoryById(int id) async {
    emit(const ExpenseCategoryLoading());
    try {
      final category = await _expenseRepository.getCategoryById(id);
      _emitSingleCategory(category);
    } catch (error) {
      emit(ExpenseCategoryError(error.toString()));
    }
  }

  Future<void> createCategory(ExpenseCategoryEntity category) async {
    emit(const ExpenseCategoryLoading());
    try {
      await _expenseRepository.createCategory(category);
      await _reloadCategories();
    } catch (error) {
      emit(ExpenseCategoryError(error.toString()));
    }
  }

  Future<void> updateCategory(ExpenseCategoryEntity category) async {
    emit(const ExpenseCategoryLoading());
    try {
      await _expenseRepository.updateCategory(category);
      await _reloadCategories();
    } catch (error) {
      emit(ExpenseCategoryError(error.toString()));
    }
  }

  Future<void> deleteCategory(int id) async {
    emit(const ExpenseCategoryLoading());
    try {
      await _expenseRepository.deleteCategory(id);
      await _reloadCategories();
    } catch (error) {
      emit(ExpenseCategoryError(error.toString()));
    }
  }

  Future<void> _reloadCategories() async {
    final categories = await _expenseRepository.getAllCategories();
    _emitCategories(categories);
  }

  void _emitSingleCategory(ExpenseCategoryEntity? category) {
    if (category == null) {
      emit(const ExpenseCategoryEmpty());
      return;
    }
    emit(ExpenseCategoryLoaded(<ExpenseCategoryEntity>[category]));
  }

  void _emitCategories(List<ExpenseCategoryEntity> categories) {
    if (categories.isEmpty) {
      emit(const ExpenseCategoryEmpty());
      return;
    }
    emit(ExpenseCategoryLoaded(categories));
  }
}
