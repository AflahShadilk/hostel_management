import 'package:sqflite/sqflite.dart';

abstract final class AuthLocalSchema {
  static Future<void> createTables(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        role TEXT NOT NULL CHECK(role IN ('owner', 'manager')),
        is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1)),
        created_at TEXT NOT NULL
      )
    ''');
  }
}
