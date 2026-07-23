import '../models/expense_category_model.dart';
import '../models/expense_model.dart';
import '../../domain/entities/expense_query.dart';

abstract class ExpenseLocalDataSource {
  Future<ExpenseCategoryModel> createCategory(ExpenseCategoryModel category);
  Future<ExpenseCategoryModel> updateCategory(ExpenseCategoryModel category);
  Future<void> deleteCategory(int id);
  Future<ExpenseCategoryModel?> getCategoryById(int id);
  Future<List<ExpenseCategoryModel>> getAllCategories();

  Future<ExpenseModel> createExpense(ExpenseModel expense);
  Future<ExpenseModel> updateExpense(ExpenseModel expense);
  Future<void> deleteExpense(int id);
  Future<ExpenseModel?> getExpenseById(int id);
  Future<List<ExpenseModel>> getAllExpenses(
      [ExpenseQuery query = const ExpenseQuery()]);
  Future<ExpenseSummaryData> getExpenseSummary();
}

class ExpenseSummaryData {
  final double todayTotal;
  final double monthTotal;
  final double yearTotal;
  final double overallTotal;

  const ExpenseSummaryData({
    required this.todayTotal,
    required this.monthTotal,
    required this.yearTotal,
    required this.overallTotal,
  });
}
