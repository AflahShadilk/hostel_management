import 'package:sqflite/sqflite.dart';

abstract final class SettingsLocalSchema {
  static const String table = 'app_settings';

  static Future<void> createTable(DatabaseExecutor database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS $table (
        id INTEGER PRIMARY KEY CHECK(id = 1),
        theme_mode TEXT NOT NULL,
        currency_symbol TEXT NOT NULL,
        currency_code TEXT NOT NULL,
        date_format TEXT NOT NULL,
        language_code TEXT NOT NULL,
        notifications_enabled INTEGER NOT NULL CHECK(notifications_enabled IN (0, 1)),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    final now = DateTime.now().toIso8601String();
    await database.insert(
        table,
        <String, Object>{
          'id': 1,
          'theme_mode': 'system',
          'currency_symbol': r'$',
          'currency_code': 'USD',
          'date_format': 'dd/MM/yyyy',
          'language_code': 'en',
          'notifications_enabled': 1,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}
