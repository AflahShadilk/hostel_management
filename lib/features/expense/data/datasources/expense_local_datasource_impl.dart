import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../models/expense_category_model.dart';
import '../models/expense_model.dart';
import '../../domain/entities/expense_query.dart';
import 'expense_local_datasource.dart';
import 'expense_local_schema.dart';

class ExpenseLocalDataSourceImpl implements ExpenseLocalDataSource {
  final AppDatabase _appDatabase;

  const ExpenseLocalDataSourceImpl(this._appDatabase);

  Future<T> _perform<T>(String operation, Future<T> Function() action) async {
    try {
      return await action();
    } on DatabaseException catch (error) {
      throw Exception('Database $operation failed: $error');
    }
  }

  @override
  Future<ExpenseCategoryModel> createCategory(
    ExpenseCategoryModel category,
  ) async {
    final database = await _appDatabase.database;
    return _perform('create expense category', () async {
      final map = category.toMap();
      final id =
          await database.insert(ExpenseLocalSchema.tableExpenseCategories, map);
      return ExpenseCategoryModel.fromMap(<String, dynamic>{...map, 'id': id});
    });
  }

  @override
  Future<ExpenseCategoryModel> updateCategory(
    ExpenseCategoryModel category,
  ) async {
    if (category.id == null) {
      throw StateError('Cannot update an expense category without an ID.');
    }
    final database = await _appDatabase.database;
    return _perform('update expense category', () async {
      final rows = await database.update(
        ExpenseLocalSchema.tableExpenseCategories,
        category.toMap(),
        where: 'id = ?',
        whereArgs: [category.id],
      );
      if (rows == 0) {
        throw StateError('Expense category not found.');
      }
      return category;
    });
  }

  @override
  Future<void> deleteCategory(int id) async {
    final database = await _appDatabase.database;
    await _perform(
      'delete expense category',
      () => database.delete(
        ExpenseLocalSchema.tableExpenseCategories,
        where: 'id = ?',
        whereArgs: [id],
      ),
    );
  }

  @override
  Future<ExpenseCategoryModel?> getCategoryById(int id) async {
    final database = await _appDatabase.database;
    return _perform('get expense category', () async {
      final rows = await database.query(
        ExpenseLocalSchema.tableExpenseCategories,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return rows.isEmpty ? null : ExpenseCategoryModel.fromMap(rows.first);
    });
  }

  @override
  Future<List<ExpenseCategoryModel>> getAllCategories() async {
    final database = await _appDatabase.database;
    return _perform('get all expense categories', () async {
      final rows =
          await database.query(ExpenseLocalSchema.tableExpenseCategories);
      return rows.map(ExpenseCategoryModel.fromMap).toList();
    });
  }

  @override
  Future<ExpenseModel> createExpense(ExpenseModel expense) async {
    final database = await _appDatabase.database;
    return _perform('create expense', () async {
      final map = expense.toMap();
      final id = await database.insert(ExpenseLocalSchema.tableExpenses, map);
      return ExpenseModel.fromMap(<String, dynamic>{...map, 'id': id});
    });
  }

  @override
  Future<ExpenseModel> updateExpense(ExpenseModel expense) async {
    if (expense.id == null) {
      throw StateError('Cannot update an expense without an ID.');
    }
    final database = await _appDatabase.database;
    return _perform('update expense', () async {
      final rows = await database.update(
        ExpenseLocalSchema.tableExpenses,
        expense.toMap(),
        where: 'id = ? AND is_deleted = 0',
        whereArgs: [expense.id],
      );
      if (rows == 0) {
        throw StateError('Expense not found.');
      }
      return expense;
    });
  }

  @override
  Future<void> deleteExpense(int id) async {
    final database = await _appDatabase.database;
    await _perform(
      'delete expense',
      () => database.update(
        ExpenseLocalSchema.tableExpenses,
        <String, Object?>{
          'is_deleted': 1,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ? AND is_deleted = 0',
        whereArgs: [id],
      ),
    );
  }

  @override
  Future<ExpenseModel?> getExpenseById(int id) async {
    final database = await _appDatabase.database;
    return _perform('get expense', () async {
      final rows = await database.query(
        ExpenseLocalSchema.tableExpenses,
        where: 'id = ? AND is_deleted = 0',
        whereArgs: [id],
        limit: 1,
      );
      return rows.isEmpty ? null : ExpenseModel.fromMap(rows.first);
    });
  }

  @override
  Future<List<ExpenseModel>> getAllExpenses([
    ExpenseQuery query = const ExpenseQuery(),
  ]) async {
    final database = await _appDatabase.database;
    return _perform('get all expenses', () async {
      final clauses = <String>['is_deleted = 0'];
      final arguments = <Object?>[];
      final searchTerm = query.searchTerm.trim();
      if (searchTerm.isNotEmpty) {
        clauses.add(
          '(title LIKE ? OR description LIKE ? OR vendor_name LIKE ? OR reference_number LIKE ?)',
        );
        final pattern = '%$searchTerm%';
        arguments.addAll(<String>[pattern, pattern, pattern, pattern]);
      }
      if (query.startDate != null) {
        clauses.add('expense_date >= ?');
        arguments.add(query.startDate!.toIso8601String());
      }
      if (query.endDate != null) {
        clauses.add('expense_date < ?');
        arguments.add(
          DateTime(
            query.endDate!.year,
            query.endDate!.month,
            query.endDate!.day + 1,
          ).toIso8601String(),
        );
      }
      final orderBy = switch (query.sort) {
        ExpenseSort.newest => 'expense_date DESC, id DESC',
        ExpenseSort.oldest => 'expense_date ASC, id ASC',
        ExpenseSort.highestAmount => 'amount DESC, id DESC',
        ExpenseSort.lowestAmount => 'amount ASC, id ASC',
      };
      final rows = await database.query(
        ExpenseLocalSchema.tableExpenses,
        where: clauses.join(' AND '),
        whereArgs: arguments,
        orderBy: orderBy,
      );
      return rows.map(ExpenseModel.fromMap).toList();
    });
  }

  @override
  Future<ExpenseSummaryData> getExpenseSummary() async {
    final database = await _appDatabase.database;
    return _perform('get expense summary', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day).toIso8601String();
      final tomorrow =
          DateTime(now.year, now.month, now.day + 1).toIso8601String();
      final month = DateTime(now.year, now.month).toIso8601String();
      final nextMonth = DateTime(now.year, now.month + 1).toIso8601String();
      final year = DateTime(now.year).toIso8601String();
      final nextYear = DateTime(now.year + 1).toIso8601String();
      final row = (await database.rawQuery('''
        SELECT
          COALESCE(SUM(CASE WHEN expense_date >= ? AND expense_date < ? THEN amount END), 0) AS today_total,
          COALESCE(SUM(CASE WHEN expense_date >= ? AND expense_date < ? THEN amount END), 0) AS month_total,
          COALESCE(SUM(CASE WHEN expense_date >= ? AND expense_date < ? THEN amount END), 0) AS year_total,
          COALESCE(SUM(amount), 0) AS overall_total
        FROM ${ExpenseLocalSchema.tableExpenses}
        WHERE is_deleted = 0
      ''', <Object?>[today, tomorrow, month, nextMonth, year, nextYear])).first;
      return ExpenseSummaryData(
        todayTotal: (row['today_total'] as num).toDouble(),
        monthTotal: (row['month_total'] as num).toDouble(),
        yearTotal: (row['year_total'] as num).toDouble(),
        overallTotal: (row['overall_total'] as num).toDouble(),
      );
    });
  }
}
