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
        gst_number    TEXT,
        website       TEXT,
        owner_user_id INTEGER NOT NULL,
        created_at    TEXT    NOT NULL,
        updated_at    TEXT    NOT NULL,
        UNIQUE(owner_user_id),
        FOREIGN KEY(owner_user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> migrateFromVersion16(Database db) async {
    await db.transaction((txn) async {
      await txn.execute('ALTER TABLE hostels ADD COLUMN gst_number TEXT');
      await txn.execute('ALTER TABLE hostels ADD COLUMN website TEXT');
    });
  }
}
