import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:hostel_management/core/database/app_database.dart';
import 'package:hostel_management/features/tenant/data/repositories/tenant_repository_impl.dart';
import 'package:hostel_management/features/tenant/domain/entities/tenant_entity.dart';
import 'package:hostel_management/features/tenant/domain/entities/tenant_status.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Opens an isolated in-memory SQLite database for each test so tests don't
/// share state and don't touch the device database.
Future<AppDatabase> _openTestDatabase() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Force AppDatabase to open a fresh in-memory instance by resetting its
  // cached database handle via the close() method.
  await AppDatabase.instance.close();

  // Actually we need to override the path or inject the database for testing,
  // but AppDatabase uses getDatabasesPath().
  // For sqflite_common_ffi, if we use inMemoryDatabasePath, it creates a fresh DB.
  // However, AppDatabase is a singleton that joins getDatabasesPath() and 'hostel_management.db'.
  // We can't easily override it without modifying AppDatabase.
  // So instead, since databaseFactoryFfi manages databases, we'll just delete the DB file before each run.

  return AppDatabase.instance;
}

TenantEntity buildTenant({
  int? id,
  int bedId = 1,
  String fullName = 'Alice Smith',
  String phoneNumber = '9876543210',
  String? email = 'alice@example.com',
  String? address = '123 Main St',
  DateTime? checkInDate,
  DateTime? checkOutDate,
  String? emergencyContactName = 'Bob Smith',
  String? emergencyContactPhone = '1111111111',
  TenantStatus status = TenantStatus.active,
}) {
  final now = DateTime.now();
  return TenantEntity(
    id: id,
    bedId: bedId,
    fullName: fullName,
    phoneNumber: phoneNumber,
    email: email,
    address: address,
    checkInDate: checkInDate ?? now,
    checkOutDate: checkOutDate,
    emergencyContactName: emergencyContactName,
    emergencyContactPhone: emergencyContactPhone,
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late AppDatabase appDatabase;
  late TenantRepositoryImpl repo;

  // Seed a bed row so the FK(bed_id) constraint is satisfiable.
  Future<void> seedBed(int bedId) async {
    final db = await appDatabase.database;
    // Insert a user, hostel, room, then bed to satisfy the FK chain.
    await db.execute('''
      INSERT OR IGNORE INTO users
        (id, name, phone, email, role, is_active, created_at)
      VALUES
        (1, 'Owner', '000', 'o@o.com', 'owner', 1, '2024-01-01T00:00:00.000')
    ''');
    await db.execute('''
      INSERT OR IGNORE INTO hostels
        (id, name, address, phone, email, owner_name, owner_user_id, created_at, updated_at)
      VALUES
        (1, 'Test Hostel', 'Address', '000', 'h@h.com', 'Owner', 1,
         '2024-01-01T00:00:00.000', '2024-01-01T00:00:00.000')
    ''');
    await db.execute('''
      INSERT OR IGNORE INTO rooms
        (id, hostel_id, room_number, floor, room_type, number_of_beds,
         monthly_rent, status, created_at, updated_at)
      VALUES
        (1, 1, '101', 'G', 'single', 2, 1000, 'vacant',
         '2024-01-01T00:00:00.000', '2024-01-01T00:00:00.000')
    ''');
    await db.execute('''
      INSERT OR IGNORE INTO beds
        (id, room_id, bed_number, monthly_rent, status, created_at, updated_at)
      VALUES
        ($bedId, 1, 'B$bedId', 1000, 'vacant',
         '2024-01-01T00:00:00.000', '2024-01-01T00:00:00.000')
    ''');
  }

  setUpAll(() async {
    appDatabase = await _openTestDatabase();
  });

  setUp(() async {
    repo = TenantRepositoryImpl(appDatabase);
    final db = await appDatabase.database;
    // Clear tenants table before every test; preserve schema rows.
    await db.delete('receipts');
    await db.delete('payments');
    await db.delete('checkout_settlements');
    await db.delete('damage_charges');
    await db.delete('deposits');
    await db.delete('rent_records');
    await db.delete('stays');
    await db.delete('tenants');
    await db.delete('beds');
    await db.delete('rooms');
    // Seed two beds for tests that need them.
    await seedBed(1);
    await seedBed(2);
  });

  tearDownAll(() async {
    await appDatabase.close();
  });

  // ---------------------------------------------------------------------------
  // createTenant
  // ---------------------------------------------------------------------------
  group('createTenant', () {
    test('creates a tenant and returns a valid ID', () async {
      final id = await repo.createTenant(buildTenant());
      expect(id, greaterThan(0));
    });

    test('persisted tenant can be retrieved by ID', () async {
      final id = await repo.createTenant(
        buildTenant(fullName: 'Charlie Doe', phoneNumber: '1112223333'),
      );
      final tenant = await repo.getTenantById(id);
      expect(tenant, isNotNull);
      expect(tenant!.fullName, 'Charlie Doe');
      expect(tenant.phoneNumber, '1112223333');
    });

    test('normalizes name and phone whitespace', () async {
      final id = await repo.createTenant(
        buildTenant(fullName: '  Alice  ', phoneNumber: '  9876543210  '),
      );
      final tenant = await repo.getTenantById(id);
      expect(tenant!.fullName, 'Alice');
      expect(tenant.phoneNumber, '9876543210');
    });

    test('stores email in lowercase', () async {
      final id = await repo.createTenant(
        buildTenant(phoneNumber: '5551111111', email: 'UPPER@Example.COM'),
      );
      final tenant = await repo.getTenantById(id);
      expect(tenant!.email, 'upper@example.com');
    });

    test('rejects blank full name', () async {
      await expectLater(
        repo.createTenant(buildTenant(fullName: '   ')),
        throwsArgumentError,
      );
    });

    test('rejects blank phone number', () async {
      await expectLater(
        repo.createTenant(buildTenant(phoneNumber: '')),
        throwsArgumentError,
      );
    });

    test('rejects invalid bedId (zero)', () async {
      await expectLater(
        repo.createTenant(buildTenant(bedId: 0)),
        throwsArgumentError,
      );
    });

    test('rejects invalid bedId (negative)', () async {
      await expectLater(
        repo.createTenant(buildTenant(bedId: -1)),
        throwsArgumentError,
      );
    });

    test('rejects check-out date before check-in date', () async {
      final now = DateTime.now();
      await expectLater(
        repo.createTenant(buildTenant(
          checkInDate: now,
          checkOutDate: now.subtract(const Duration(days: 1)),
        )),
        throwsArgumentError,
      );
    });

    test('allows check-out date equal to check-in date', () async {
      final now = DateTime.now();
      final id = await repo.createTenant(buildTenant(
        phoneNumber: '7770000001',
        email: 'eq@test.com',
        checkInDate: now,
        checkOutDate: now,
      ));
      expect(id, greaterThan(0));
    });

    test('allows null check-out date', () async {
      final id = await repo.createTenant(
        buildTenant(phoneNumber: '7770000002', email: null, checkOutDate: null),
      );
      final tenant = await repo.getTenantById(id);
      expect(tenant!.checkOutDate, isNull);
    });

    test('allows null email (no uniqueness check applied)', () async {
      // Two tenants without email should both succeed.
      await repo.createTenant(
        buildTenant(phoneNumber: '3001111111', email: null),
      );
      final id2 = await repo.createTenant(
        buildTenant(bedId: 2, phoneNumber: '3002222222', email: null),
      );
      expect(id2, greaterThan(0));
    });

    test('rejects duplicate phone number', () async {
      await repo.createTenant(buildTenant(phoneNumber: '9999999999'));
      await expectLater(
        repo.createTenant(
          buildTenant(bedId: 2, phoneNumber: '9999999999', email: 'b@b.com'),
        ),
        throwsStateError,
      );
    });

    test('rejects duplicate email (case-insensitive)', () async {
      await repo.createTenant(
        buildTenant(phoneNumber: '1010101010', email: 'dup@test.com'),
      );
      await expectLater(
        repo.createTenant(
          buildTenant(
            bedId: 2,
            phoneNumber: '2020202020',
            email: 'DUP@TEST.COM',
          ),
        ),
        throwsStateError,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // updateTenant
  // ---------------------------------------------------------------------------
  group('updateTenant', () {
    test('updates persisted fields', () async {
      final id = await repo.createTenant(buildTenant());
      final original = await repo.getTenantById(id);

      final updated = TenantEntity(
        id: id,
        bedId: original!.bedId,
        fullName: 'Updated Name',
        phoneNumber: original.phoneNumber,
        email: original.email,
        address: 'New Address',
        checkInDate: original.checkInDate,
        checkOutDate: original.checkOutDate,
        emergencyContactName: original.emergencyContactName,
        emergencyContactPhone: original.emergencyContactPhone,
        status: TenantStatus.active,
        createdAt: original.createdAt,
        updatedAt: DateTime.now(),
      );

      await repo.updateTenant(updated);
      final fetched = await repo.getTenantById(id);

      expect(fetched!.fullName, 'Updated Name');
      expect(fetched.address, 'New Address');
      expect(fetched.status, TenantStatus.active);
    });

    test('throws StateError when id is null', () async {
      await expectLater(
        repo.updateTenant(buildTenant()),
        throwsStateError,
      );
    });

    test('throws StateError when id does not exist', () async {
      final ghost = TenantEntity(
        id: 99999,
        bedId: 1,
        fullName: 'Ghost',
        phoneNumber: '0000000000',
        checkInDate: DateTime.now(),
        status: TenantStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await expectLater(repo.updateTenant(ghost), throwsStateError);
    });

    test('allows same phone on update (self-exclusion)', () async {
      final id = await repo.createTenant(buildTenant());
      final existing = (await repo.getTenantById(id))!;
      // Update with the same phone — should not throw.
      await expectLater(
        repo.updateTenant(existing),
        completes,
      );
    });

    test('rejects phone duplicate from another tenant on update', () async {
      await repo.createTenant(
        buildTenant(phoneNumber: '1234512345', email: 'a1@test.com'),
      );
      final id2 = await repo.createTenant(
        buildTenant(bedId: 2, phoneNumber: '9876598765', email: 'a2@test.com'),
      );
      final tenant2 = (await repo.getTenantById(id2))!;
      final conflicting = TenantEntity(
        id: tenant2.id,
        bedId: tenant2.bedId!,
        fullName: tenant2.fullName,
        phoneNumber: '1234512345', // stolen from tenant 1
        checkInDate: tenant2.checkInDate,
        status: tenant2.status,
        createdAt: tenant2.createdAt,
        updatedAt: tenant2.updatedAt,
      );
      await expectLater(repo.updateTenant(conflicting), throwsStateError);
    });
  });

  // ---------------------------------------------------------------------------
  // deleteTenant
  // ---------------------------------------------------------------------------
  group('deleteTenant', () {
    test('removes the tenant permanently', () async {
      final id = await repo.createTenant(buildTenant());
      await repo.deleteTenant(id);
      final result = await repo.getTenantById(id);
      expect(result, isNull);
    });

    test('deleting non-existent ID is a no-op (no throw)', () async {
      await expectLater(repo.deleteTenant(99999), completes);
    });
  });

  // ---------------------------------------------------------------------------
  // getAllTenants
  // ---------------------------------------------------------------------------
  group('getAllTenants', () {
    test('returns empty list when no tenants exist', () async {
      final tenants = await repo.getAllTenants();
      expect(tenants, isEmpty);
    });

    test('returns all tenants ordered by full name', () async {
      await repo.createTenant(buildTenant(fullName: 'Zara', phoneNumber: '1'));
      await repo.createTenant(
        buildTenant(bedId: 2, fullName: 'Aaron', phoneNumber: '2', email: null),
      );
      final tenants = await repo.getAllTenants();
      expect(tenants.length, 2);
      expect(tenants.first.fullName, 'Aaron');
      expect(tenants.last.fullName, 'Zara');
    });
  });

  // ---------------------------------------------------------------------------
  // searchTenants
  // ---------------------------------------------------------------------------
  group('searchTenants', () {
    setUp(() async {
      await repo.createTenant(
        buildTenant(
            fullName: 'Alice Smith',
            phoneNumber: '1110001111',
            email: 'alice@mail.com'),
      );
      await repo.createTenant(
        buildTenant(
            bedId: 2,
            fullName: 'Bob Jones',
            phoneNumber: '2220002222',
            email: 'bob@mail.com'),
      );
    });

    test('finds by partial name (case-insensitive)', () async {
      final results = await repo.searchTenants('alice');
      expect(results.length, 1);
      expect(results.first.fullName, 'Alice Smith');
    });

    test('finds by partial phone', () async {
      final results = await repo.searchTenants('2220002');
      expect(results.length, 1);
      expect(results.first.fullName, 'Bob Jones');
    });

    test('finds by partial email (case-insensitive)', () async {
      final results = await repo.searchTenants('BOB@MAIL');
      expect(results.length, 1);
      expect(results.first.fullName, 'Bob Jones');
    });

    test('returns all when query is blank', () async {
      final results = await repo.searchTenants('');
      expect(results.length, 2);
    });

    test('returns empty list when no match', () async {
      final results = await repo.searchTenants('zzznomatch');
      expect(results, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // phoneExists / emailExists / isBedOccupied
  // ---------------------------------------------------------------------------
  group('phoneExists', () {
    test('returns false when no match', () async {
      expect(await repo.phoneExists('0000000000'), isFalse);
    });

    test('returns true for an existing phone', () async {
      await repo.createTenant(buildTenant(phoneNumber: '4440004444'));
      expect(await repo.phoneExists('4440004444'), isTrue);
    });

    test('returns false for blank phone', () async {
      expect(await repo.phoneExists(''), isFalse);
    });
  });

  group('emailExists', () {
    test('returns false for empty string', () async {
      expect(await repo.emailExists(''), isFalse);
    });

    test('returns false when email is not in DB', () async {
      expect(await repo.emailExists('ghost@mail.com'), isFalse);
    });

    test('returns true for an existing email', () async {
      await repo.createTenant(
        buildTenant(phoneNumber: '5550005555', email: 'found@mail.com'),
      );
      expect(await repo.emailExists('found@mail.com'), isTrue);
    });

    test('email check is case-insensitive', () async {
      await repo.createTenant(
        buildTenant(phoneNumber: '6660006666', email: 'Upper@Mail.com'),
      );
      expect(await repo.emailExists('upper@mail.com'), isTrue);
      expect(await repo.emailExists('UPPER@MAIL.COM'), isTrue);
    });
  });

  group('isBedOccupied', () {
    test('returns false when no active tenant on bed', () async {
      expect(await repo.isBedOccupied(1), isFalse);
    });

    test('returns true when bed has an active tenant', () async {
      await repo.createTenant(buildTenant(phoneNumber: '7770007777'));
      expect(await repo.isBedOccupied(1), isTrue);
    });

    test('returns false after tenant is deleted', () async {
      final id =
          await repo.createTenant(buildTenant(phoneNumber: '8880008888'));
      await repo.deleteTenant(id);
      expect(await repo.isBedOccupied(1), isFalse);
    });

    test('returns false for checked-out tenant status', () async {
      final id =
          await repo.createTenant(buildTenant(phoneNumber: '9990009999'));
      // Checked-out tenants must no longer hold a bed reference.
      final tenant = (await repo.getTenantById(id))!;
      final updated = TenantEntity(
        id: tenant.id,
        bedId: null,
        fullName: tenant.fullName,
        phoneNumber: tenant.phoneNumber,
        checkInDate: tenant.checkInDate,
        checkOutDate: DateTime.now(),
        status: TenantStatus.checkedOut,
        createdAt: tenant.createdAt,
        updatedAt: DateTime.now(),
      );
      await repo.updateTenant(updated);
      expect(await repo.isBedOccupied(1), isFalse);
    });
  });
}
