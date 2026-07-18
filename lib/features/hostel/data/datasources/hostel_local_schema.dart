import 'package:sqflite/sqflite.dart';

abstract final class HostelLocalSchema {
  static Future<void> createTables(Database db) async {
    await db.execute('''
      CREATE TABLE hostels (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        name          TEXT    NOT NULL,
        logo_path     TEXT,
        address       TEXT    NOT NULL,
        phone         TEXT    NOT NULL,
        email         TEXT    NOT NULL,
        owner_name    TEXT    NOT NULL,
        owner_user_id INTEGER NOT NULL,
        created_at    TEXT    NOT NULL,
        updated_at    TEXT    NOT NULL,
        UNIQUE(owner_user_id),
        FOREIGN KEY(owner_user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
  }
}
