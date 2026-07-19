import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:hostel_management/features/rent/data/datasources/rent_local_schema.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  Future<void> createVersion4Tables(Database database) async {
    await database.execute('''
      CREATE TABLE stays (
        id INTEGER PRIMARY KEY AUTOINCREMENT, tenant_id INTEGER NOT NULL,
        check_in_date TEXT NOT NULL, check_out_date TEXT, status TEXT NOT NULL,
        created_at TEXT NOT NULL, updated_at TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE rent_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT, stay_id INTEGER NOT NULL,
        rent_period TEXT NOT NULL, due_date TEXT NOT NULL, amount_due REAL NOT NULL,
        amount_paid REAL NOT NULL DEFAULT 0, status TEXT NOT NULL,
        created_at TEXT NOT NULL, updated_at TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT, rent_record_id INTEGER NOT NULL,
        amount REAL NOT NULL, payment_date TEXT NOT NULL, payment_method TEXT,
        status TEXT NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE receipts (
        id INTEGER PRIMARY KEY AUTOINCREMENT, payment_id INTEGER NOT NULL,
        receipt_number TEXT NOT NULL, issued_at TEXT NOT NULL,
        created_at TEXT NOT NULL, updated_at TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE deposits (
        id INTEGER PRIMARY KEY AUTOINCREMENT, stay_id INTEGER NOT NULL,
        amount REAL NOT NULL, status TEXT NOT NULL,
        created_at TEXT NOT NULL, updated_at TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE damage_charges (
        id INTEGER PRIMARY KEY AUTOINCREMENT, stay_id INTEGER NOT NULL,
        description TEXT NOT NULL, amount REAL NOT NULL, status TEXT NOT NULL,
        created_at TEXT NOT NULL, updated_at TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE checkout_settlements (
        id INTEGER PRIMARY KEY AUTOINCREMENT, stay_id INTEGER NOT NULL,
        rent_due REAL NOT NULL DEFAULT 0, deposit_adjustment REAL NOT NULL DEFAULT 0,
        damage_charges REAL NOT NULL DEFAULT 0, final_amount REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL
      )
    ''');
  }

  test('creates rent tables with their required foreign keys and constraints',
      () async {
    final database =
        await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(database.close);
    await database.execute('PRAGMA foreign_keys = ON');
    await database.execute('CREATE TABLE tenants (id INTEGER PRIMARY KEY)');
    await database.execute('CREATE TABLE rooms (id INTEGER PRIMARY KEY)');
    await database.execute('''
      CREATE TABLE beds (
        id INTEGER PRIMARY KEY,
        room_id INTEGER NOT NULL REFERENCES rooms(id)
      )
    ''');

    await RentLocalSchema.createTables(database);

    final tables = await database.rawQuery('''
      SELECT name FROM sqlite_master
      WHERE type = 'table' AND name NOT LIKE 'sqlite_%'
      ORDER BY name
    ''');
    expect(
      tables.map((row) => row['name']),
      containsAll(<String>[
        RentLocalSchema.tableStays,
        RentLocalSchema.tableRentRecords,
        RentLocalSchema.tablePayments,
        RentLocalSchema.tableReceipts,
        RentLocalSchema.tableDeposits,
        RentLocalSchema.tableDamageCharges,
        RentLocalSchema.tableCheckoutSettlements,
      ]),
    );

    const timestamp = '2026-07-19T00:00:00.000';
    await database.insert('tenants', {'id': 1});
    await database.insert('rooms', {'id': 1});
    await database.insert('beds', {'id': 1, 'room_id': 1});
    final stayId = await database.insert(RentLocalSchema.tableStays, {
      'tenant_id': 1,
      'room_id': 1,
      'bed_id': 1,
      'check_in_date': timestamp,
      'monthly_rent_snapshot': 1000,
      'daily_rate': 33.33,
      'status': 'active',
      'created_at': timestamp,
      'updated_at': timestamp,
    });
    final rentRecordId = await database.insert(RentLocalSchema.tableRentRecords, {
      'stay_id': stayId,
      'rent_period': '2026-07',
      'billing_month': 7,
      'billing_year': 2026,
      'generated_at': timestamp,
      'due_date': timestamp,
      'amount_due': 1000,
      'status': 'pending',
      'created_at': timestamp,
      'updated_at': timestamp,
    });
    final paymentId = await database.insert(RentLocalSchema.tablePayments, {
      'rent_record_id': rentRecordId,
      'amount': 1000,
      'payment_date': timestamp,
      'payment_method': 'cash',
      'status': 'completed',
      'created_at': timestamp,
      'updated_at': timestamp,
    });
    await database.insert(RentLocalSchema.tableReceipts, {
      'payment_id': paymentId,
      'receipt_number': 'RCT-0001',
      'issued_at': timestamp,
      'payment_amount_snapshot': 1000,
      'payment_method_snapshot': 'cash',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await expectLater(
      database.insert(RentLocalSchema.tableReceipts, {
        'payment_id': paymentId,
        'receipt_number': 'RCT-0002',
        'issued_at': timestamp,
        'payment_amount_snapshot': 1000,
        'payment_method_snapshot': 'cash',
        'created_at': timestamp,
        'updated_at': timestamp,
      }),
      throwsA(isA<DatabaseException>()),
    );
    await expectLater(
      database.insert(RentLocalSchema.tablePayments, {
        'rent_record_id': 999,
        'amount': 10,
        'payment_date': timestamp,
        'payment_method': 'cash',
        'status': 'completed',
        'created_at': timestamp,
        'updated_at': timestamp,
      }),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('migrates v4 financial history without cascade foreign keys', () async {
    final database =
        await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(database.close);
    await database.execute('PRAGMA foreign_keys = ON');
    await database.execute('CREATE TABLE tenants (id INTEGER PRIMARY KEY)');
    await database.execute('CREATE TABLE rooms (id INTEGER PRIMARY KEY)');
    await database.execute('CREATE TABLE beds (id INTEGER PRIMARY KEY)');
    await createVersion4Tables(database);

    const timestamp = '2026-07-19T00:00:00.000';
    await database.insert('tenants', {'id': 1});
    await database.insert('stays', {
      'id': 1,
      'tenant_id': 1,
      'check_in_date': timestamp,
      'status': 'active',
      'created_at': timestamp,
      'updated_at': timestamp,
    });
    await database.insert('rent_records', {
      'id': 1,
      'stay_id': 1,
      'rent_period': '2026-07',
      'due_date': timestamp,
      'amount_due': 1000,
      'status': 'pending',
      'created_at': timestamp,
      'updated_at': timestamp,
    });
    await database.insert('payments', {
      'id': 1,
      'rent_record_id': 1,
      'amount': 1000,
      'payment_date': timestamp,
      'status': 'completed',
      'created_at': timestamp,
      'updated_at': timestamp,
    });
    await database.insert('receipts', {
      'id': 1,
      'payment_id': 1,
      'receipt_number': 'RCT-0001',
      'issued_at': timestamp,
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await RentLocalSchema.migrateFromVersion4(database);

    final stay = (await database.query('stays')).single;
    final rentRecord = (await database.query('rent_records')).single;
    final payment = (await database.query('payments')).single;
    final receipt = (await database.query('receipts')).single;
    expect(stay['room_id'], isNull);
    expect(stay['bed_id'], isNull);
    expect(rentRecord['billing_month'], 7);
    expect(rentRecord['billing_year'], 2026);
    expect(rentRecord['generated_at'], timestamp);
    expect(payment['payment_method'], 'unknown');
    expect(receipt['payment_amount_snapshot'], 1000);
    expect(receipt['payment_method_snapshot'], 'unknown');

    final foreignKey =
        await database.rawQuery('PRAGMA foreign_key_list(rent_records)');
    expect(foreignKey.single['on_delete'], 'RESTRICT');
    await expectLater(
      database.delete('stays', where: 'id = ?', whereArgs: [1]),
      throwsA(isA<DatabaseException>()),
    );
  });
}
