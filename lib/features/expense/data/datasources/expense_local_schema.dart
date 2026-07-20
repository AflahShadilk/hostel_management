import 'package:sqflite/sqflite.dart';

/// Defines the persistent storage for the Expense Management module.
abstract final class ExpenseLocalSchema {
  static const String tableExpenseCategories = 'expense_categories';
  static const String tableExpenses = 'expenses';

  static Future<void> createTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableExpenseCategories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1)),
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableExpenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        amount REAL NOT NULL CHECK(amount > 0),
        expense_date TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        reference_number TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,

        FOREIGN KEY(category_id)
          REFERENCES $tableExpenseCategories(id)
          ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_expenses_expense_date
      ON $tableExpenses(expense_date)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_expenses_category_id
      ON $tableExpenses(category_id)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_expenses_created_at
      ON $tableExpenses(created_at)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_expense_categories_name
      ON $tableExpenseCategories(name)
    ''');
  }
}
