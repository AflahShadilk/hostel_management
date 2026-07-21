import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:hostel_management/features/rent/data/repositories/rent_collection_repository_impl.dart';
import 'package:hostel_management/core/database/app_database.dart';

class MockAppDatabase implements AppDatabase {
  final Database mockDatabase;
  MockAppDatabase(this.mockDatabase);

  @override
  Future<Database> get database async => mockDatabase;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Database database;
  late MockAppDatabase mockAppDatabase;
  late RentCollectionRepositoryImpl repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    database = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await database.execute('PRAGMA foreign_keys = ON');

    // Create required tables manually or using their respective schemas
    await database.execute('''
      CREATE TABLE tenants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE rooms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        room_number TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE beds (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        room_id INTEGER NOT NULL,
        bed_number TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE stays (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tenant_id INTEGER NOT NULL,
        room_id INTEGER NOT NULL,
        bed_id INTEGER NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE rent_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        stay_id INTEGER NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        generated_at TEXT NOT NULL,
        due_date TEXT NOT NULL,
        amount_due REAL NOT NULL,
        amount_paid REAL NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    mockAppDatabase = MockAppDatabase(database);

    repository = RentCollectionRepositoryImpl(mockAppDatabase);
  });

  tearDown(() async {
    await database.close();
  });

  test('getRentCollectionItems returns aggregated list excluding cancelled', () async {
    // Insert dummy data
    await database.insert('tenants', {'id': 1, 'full_name': 'John Doe'});
    await database.insert('rooms', {'id': 1, 'room_number': '101'});
    await database.insert('beds', {'id': 1, 'room_id': 1, 'bed_number': 'A'});
    await database.insert('stays', {'id': 1, 'tenant_id': 1, 'room_id': 1, 'bed_id': 1});

    const timestamp = '2026-07-20T00:00:00.000';
    // Active rent record
    await database.insert('rent_records', {
      'id': 1,
      'stay_id': 1,
      'start_date': timestamp,
      'end_date': timestamp,
      'generated_at': timestamp,
      'due_date': timestamp,
      'amount_due': 5000.0,
      'amount_paid': 0.0,
      'status': 'pending',
      'created_at': timestamp,
      'updated_at': timestamp,
    });
    // Cancelled rent record (should be excluded)
    await database.insert('rent_records', {
      'id': 2,
      'stay_id': 1,
      'start_date': timestamp,
      'end_date': timestamp,
      'generated_at': timestamp,
      'due_date': timestamp,
      'amount_due': 5000.0,
      'amount_paid': 0.0,
      'status': 'cancelled',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    final items = await repository.getRentCollectionItems();

    expect(items.length, 1);
    final item = items.first;
    expect(item.tenantName, 'John Doe');
    expect(item.roomNumber, '101');
    expect(item.bedNumber, 'A');
    expect(item.rentRecord.id, 1);
    expect(item.rentRecord.status, 'pending');
  });
}
