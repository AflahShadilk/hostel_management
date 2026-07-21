import '../entities/expense_category_entity.dart';
import '../entities/expense_entity.dart';
import '../entities/expense_query.dart';
import '../entities/expense_summary_entity.dart';

abstract interface class ExpenseRepository {
  Future<ExpenseCategoryEntity> createCategory(ExpenseCategoryEntity category);
  Future<ExpenseCategoryEntity> updateCategory(ExpenseCategoryEntity category);
  Future<void> deleteCategory(int id);
  Future<ExpenseCategoryEntity?> getCategoryById(int id);
  Future<List<ExpenseCategoryEntity>> getAllCategories();

  Future<ExpenseEntity> createExpense(ExpenseEntity expense);
  Future<ExpenseEntity> updateExpense(ExpenseEntity expense);
  Future<void> deleteExpense(int id);
  Future<ExpenseEntity?> getExpenseById(int id);
  Future<List<ExpenseEntity>> getAllExpenses([ExpenseQuery query = const ExpenseQuery()]);
  Future<ExpenseSummaryEntity> getExpenseSummary();
}
