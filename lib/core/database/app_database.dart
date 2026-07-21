import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'database_constants.dart';
import '../../features/auth/data/datasources/auth_local_schema.dart';
import '../../features/expense/data/datasources/expense_local_schema.dart';
import '../../features/hostel/data/datasources/hostel_local_schema.dart';
import '../../features/room/data/datasources/room_local_schema.dart';
import '../../features/rent/data/datasources/rent_local_schema.dart';
import '../../features/settings/data/datasources/settings_local_schema.dart';
import '../../features/tenant/data/datasources/tenant_local_schema.dart';

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

    // NOTE: Because the app is in early development and remains on database
    // version 1, any existing local development database created prior to this
    // addition must be cleared (uninstall/reinstall app) to trigger onCreate.
    await AuthLocalSchema.createTables(db);

    // hostels references users(id) so must be created after users.
    await HostelLocalSchema.createTables(db);

    // rooms references hostels, beds references rooms.
    await RoomLocalSchema.createTables(db);

    // tenants references beds.
    await TenantLocalSchema.createTable(db);

    // Rent management tables reference tenants, then each other.
    await RentLocalSchema.createTables(db);

    await ExpenseLocalSchema.createTables(db);
    await SettingsLocalSchema.createTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Sequential version checks ensure multi-version upgrades are handled
    // safely in a single pass without data loss.
    if (oldVersion < 2) {
      // v1 → v2: introduce the tenants table.
      await TenantLocalSchema.createTable(db);
    }

    if (oldVersion < 3) {
      await TenantLocalSchema.migrateFromVersion2(db);
    }

    if (oldVersion < 4) {
      await RentLocalSchema.createTables(db);
    }

    if (oldVersion < 5) {
      await RentLocalSchema.migrateFromVersion4(db);
    }

    if (oldVersion < 6) {
      await db.transaction((txn) async {
        await ExpenseLocalSchema.createTables(txn);
      });
    }

    if (oldVersion < 7) {
      await SettingsLocalSchema.createTable(db);
    }

    if (oldVersion < 8) {
      await RoomLocalSchema.migrateFromVersion7(db);
    }

    if (oldVersion < 9) {
      await TenantLocalSchema.migrateFromVersion8(db);
    }

    if (oldVersion < 10) {
      await RentLocalSchema.migrateFromVersion9(db);
    }

    if (oldVersion < 11) {
      await RentLocalSchema.migrateFromVersion10(db);
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Opens a fresh connection after a backup or restore operation has closed
  /// the active database connection.
  Future<void> reopen() async {
    await database;
  }
}
