import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../models/expense_category_model.dart';
import '../models/expense_model.dart';
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
      final id = await database.insert(ExpenseLocalSchema.tableExpenseCategories, map);
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
      final rows = await database.query(ExpenseLocalSchema.tableExpenseCategories);
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
        where: 'id = ?',
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
      () => database.delete(
        ExpenseLocalSchema.tableExpenses,
        where: 'id = ?',
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
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return rows.isEmpty ? null : ExpenseModel.fromMap(rows.first);
    });
  }

  @override
  Future<List<ExpenseModel>> getAllExpenses() async {
    final database = await _appDatabase.database;
    return _perform('get all expenses', () async {
      final rows = await database.query(ExpenseLocalSchema.tableExpenses);
      return rows.map(ExpenseModel.fromMap).toList();
    });
  }
}
