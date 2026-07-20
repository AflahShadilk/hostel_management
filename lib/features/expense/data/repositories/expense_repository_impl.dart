import '../../domain/entities/expense_category_entity.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_local_datasource.dart';
import '../models/expense_category_model.dart';
import '../models/expense_model.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseLocalDataSource _localDataSource;

  const ExpenseRepositoryImpl(this._localDataSource);

  @override
  Future<ExpenseCategoryEntity> createCategory(
    ExpenseCategoryEntity category,
  ) =>
      _localDataSource.createCategory(ExpenseCategoryModel.fromEntity(category));

  @override
  Future<ExpenseCategoryEntity> updateCategory(
    ExpenseCategoryEntity category,
  ) =>
      _localDataSource.updateCategory(ExpenseCategoryModel.fromEntity(category));

  @override
  Future<void> deleteCategory(int id) => _localDataSource.deleteCategory(id);

  @override
  Future<ExpenseCategoryEntity?> getCategoryById(int id) =>
      _localDataSource.getCategoryById(id);

  @override
  Future<List<ExpenseCategoryEntity>> getAllCategories() =>
      _localDataSource.getAllCategories();

  @override
  Future<ExpenseEntity> createExpense(ExpenseEntity expense) =>
      _localDataSource.createExpense(ExpenseModel.fromEntity(expense));

  @override
  Future<ExpenseEntity> updateExpense(ExpenseEntity expense) =>
      _localDataSource.updateExpense(ExpenseModel.fromEntity(expense));

  @override
  Future<void> deleteExpense(int id) => _localDataSource.deleteExpense(id);

  @override
  Future<ExpenseEntity?> getExpenseById(int id) =>
      _localDataSource.getExpenseById(id);

  @override
  Future<List<ExpenseEntity>> getAllExpenses() =>
      _localDataSource.getAllExpenses();
}
