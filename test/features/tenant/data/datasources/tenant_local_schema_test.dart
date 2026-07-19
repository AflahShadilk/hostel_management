import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:hostel_management/features/tenant/data/datasources/tenant_local_schema.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('v2 migration preserves history and releases checked-out beds', () async {
    final database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(database.close);

    await database.execute(
      'CREATE TABLE rooms (id INTEGER PRIMARY KEY, hostel_id INTEGER NOT NULL)',
    );
    await database.execute(
      'CREATE TABLE beds (id INTEGER PRIMARY KEY, room_id INTEGER NOT NULL)',
    );
    await database.insert('rooms', {'id': 1, 'hostel_id': 10});
    await database.insert('rooms', {'id': 2, 'hostel_id': 10});
    await database.insert('beds', {'id': 101, 'room_id': 1});
    await database.insert('beds', {'id': 102, 'room_id': 2});

    await database.execute('''
      CREATE TABLE tenants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bed_id INTEGER NOT NULL UNIQUE,
        full_name TEXT NOT NULL,
        phone_number TEXT NOT NULL,
        email TEXT,
        address TEXT,
        check_in_date TEXT NOT NULL,
        check_out_date TEXT,
        emergency_contact_name TEXT,
        emergency_contact_phone TEXT,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    const timestamp = '2026-07-19T00:00:00.000';
    await database.insert('tenants', {
      'id': 1,
      'bed_id': 101,
      'full_name': 'Active Tenant',
      'phone_number': '111',
      'check_in_date': timestamp,
      'status': 'active',
      'created_at': timestamp,
      'updated_at': timestamp,
    });
    await database.insert('tenants', {
      'id': 2,
      'bed_id': 102,
      'full_name': 'Checked-out Tenant',
      'phone_number': '222',
      'check_in_date': timestamp,
      'check_out_date': timestamp,
      'status': 'checked_out',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await TenantLocalSchema.migrateFromVersion2(database);

    final tenants = await database.query('tenants', orderBy: 'id');
    expect(tenants, hasLength(2));
    expect(tenants[0]['bed_id'], 101);
    expect(tenants[0]['hostel_id'], 10);
    expect(tenants[1]['bed_id'], isNull);
    expect(tenants[1]['hostel_id'], 10);
    expect(tenants[1]['status'], 'checked_out');

    await database.insert('tenants', {
      'bed_id': 102,
      'full_name': 'New Tenant',
      'phone_number': '333',
      'check_in_date': timestamp,
      'status': 'active',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await expectLater(
      database.insert('tenants', {
        'bed_id': 101,
        'full_name': 'Duplicate Assignment',
        'phone_number': '444',
        'check_in_date': timestamp,
        'status': 'active',
        'created_at': timestamp,
        'updated_at': timestamp,
      }),
      throwsA(isA<DatabaseException>()),
    );
  });
}
