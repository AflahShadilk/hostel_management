import '../../domain/entities/expense_category_entity.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/entities/expense_query.dart';
import '../../domain/entities/expense_summary_entity.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_local_datasource.dart';
import '../models/expense_category_model.dart';
import '../models/expense_model.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseLocalDataSource _localDataSource;

  const ExpenseRepositoryImpl(this._localDataSource);

  Future<void> _validateCategoryName(
    ExpenseCategoryEntity category, {
    int? excludingId,
  }) async {
    if (category.name.trim().isEmpty) {
      throw ArgumentError('Expense category name is required.');
    }
    final categories = await _localDataSource.getAllCategories();
    final name = category.name.trim().toLowerCase();
    if (categories.any(
      (existing) =>
          existing.id != excludingId &&
          existing.name.trim().toLowerCase() == name,
    )) {
      throw StateError('An expense category with this name already exists.');
    }
  }

  Future<void> _validateExpense(ExpenseEntity expense) async {
    if (await _localDataSource.getCategoryById(expense.categoryId) == null) {
      throw StateError('Expense category not found.');
    }
    if (expense.title.trim().isEmpty) {
      throw ArgumentError('Expense title is required.');
    }
    if (!expense.amount.isFinite || expense.amount <= 0) {
      throw ArgumentError('Expense amount must be greater than zero.');
    }
    if (expense.paymentMethod.trim().isEmpty) {
      throw ArgumentError('Payment method is required.');
    }
  }

  @override
  Future<ExpenseCategoryEntity> createCategory(
    ExpenseCategoryEntity category,
  ) async {
    await _validateCategoryName(category);
    return _localDataSource.createCategory(
      ExpenseCategoryModel.fromEntity(category),
    );
  }

  @override
  Future<ExpenseCategoryEntity> updateCategory(
    ExpenseCategoryEntity category,
  ) async {
    if (category.id == null ||
        await _localDataSource.getCategoryById(category.id!) == null) {
      throw StateError('Expense category not found.');
    }
    await _validateCategoryName(category, excludingId: category.id);
    return _localDataSource.updateCategory(
      ExpenseCategoryModel.fromEntity(category),
    );
  }

  @override
  Future<void> deleteCategory(int id) async {
    if (await _localDataSource.getCategoryById(id) == null) {
      throw StateError('Expense category not found.');
    }
    final expenses = await _localDataSource.getAllExpenses();
    if (expenses.any((expense) => expense.categoryId == id)) {
      throw StateError('Cannot delete an expense category with expenses.');
    }
    await _localDataSource.deleteCategory(id);
  }

  @override
  Future<ExpenseCategoryEntity?> getCategoryById(int id) =>
      _localDataSource.getCategoryById(id);

  @override
  Future<List<ExpenseCategoryEntity>> getAllCategories() =>
      _localDataSource.getAllCategories();

  @override
  Future<ExpenseEntity> createExpense(ExpenseEntity expense) async {
    await _validateExpense(expense);
    return _localDataSource.createExpense(ExpenseModel.fromEntity(expense));
  }

  @override
  Future<ExpenseEntity> updateExpense(ExpenseEntity expense) async {
    if (expense.id == null ||
        await _localDataSource.getExpenseById(expense.id!) == null) {
      throw StateError('Expense not found.');
    }
    await _validateExpense(expense);
    return _localDataSource.updateExpense(ExpenseModel.fromEntity(expense));
  }

  @override
  Future<void> deleteExpense(int id) async {
    if (await _localDataSource.getExpenseById(id) == null) {
      throw StateError('Expense not found.');
    }
    await _localDataSource.deleteExpense(id);
  }

  @override
  Future<ExpenseEntity?> getExpenseById(int id) =>
      _localDataSource.getExpenseById(id);

  @override
  Future<List<ExpenseEntity>> getAllExpenses([
    ExpenseQuery query = const ExpenseQuery(),
  ]) =>
      _localDataSource.getAllExpenses(query);

  @override
  Future<ExpenseSummaryEntity> getExpenseSummary() async {
    final summary = await _localDataSource.getExpenseSummary();
    return ExpenseSummaryEntity(
      todayTotal: summary.todayTotal,
      monthTotal: summary.monthTotal,
      yearTotal: summary.yearTotal,
      overallTotal: summary.overallTotal,
    );
  }
}
