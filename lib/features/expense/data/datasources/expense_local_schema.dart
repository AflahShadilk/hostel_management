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
        is_default INTEGER NOT NULL DEFAULT 0 CHECK(is_default IN (0, 1)),
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
        vendor_name TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0 CHECK(is_deleted IN (0, 1)),

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
      CREATE INDEX IF NOT EXISTS idx_expenses_is_deleted
      ON $tableExpenses(is_deleted)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_expense_categories_name
      ON $tableExpenseCategories(name)
    ''');
  }

  static Future<void> migrateFromVersion12(DatabaseExecutor db) async {
    await db.execute(
      'ALTER TABLE $tableExpenseCategories ADD COLUMN is_default '
      'INTEGER NOT NULL DEFAULT 0 CHECK(is_default IN (0, 1))',
    );
    await db.execute(
      'ALTER TABLE $tableExpenses ADD COLUMN vendor_name TEXT',
    );
    await db.execute(
      'ALTER TABLE $tableExpenses ADD COLUMN is_deleted '
      'INTEGER NOT NULL DEFAULT 0 CHECK(is_deleted IN (0, 1))',
    );
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_expenses_is_deleted
      ON $tableExpenses(is_deleted)
    ''');
    await ensureDefaultCategories(db);
  }

  static Future<void> ensureDefaultCategories(DatabaseExecutor db) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM $tableExpenseCategories',
    );
    if (Sqflite.firstIntValue(result) != 0) {
      return;
    }

    final now = DateTime.now().toIso8601String();
    for (final name in _defaultCategoryNames) {
      await db.insert(tableExpenseCategories, <String, Object?>{
        'name': name,
        'is_active': 1,
        'is_default': 1,
        'created_at': now,
      });
    }
  }

  static const List<String> _defaultCategoryNames = <String>[
    'Electricity',
    'Water',
    'Internet',
    'Staff Salary',
    'Cleaning',
    'Maintenance',
    'Gas',
    'Office Supplies',
    'Miscellaneous',
  ];
}
