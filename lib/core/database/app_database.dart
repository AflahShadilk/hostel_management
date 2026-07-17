import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'database_constants.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final path = join(
      await getDatabasesPath(),
      DatabaseConstants.databaseName,
    );

    return openDatabase(
      path,
      version: DatabaseConstants.databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Foreign key constraints are disabled by SQLite by default and must be
    // re-enabled on every connection, not just during initial creation.
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    // Feature tables are added here as each feature module is implemented.
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Sequential version checks (if oldVersion < N) will be added here as
    // the schema evolves, safely handling multi-version upgrades without
    // data loss.
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
