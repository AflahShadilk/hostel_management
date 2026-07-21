import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:hostel_management/core/database/app_database.dart';
import 'package:hostel_management/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:hostel_management/features/room/data/repositories/bed_repository_impl.dart';
import 'package:hostel_management/features/room/data/repositories/room_management_repository_impl.dart';
import 'package:hostel_management/features/room/domain/entities/bed_status.dart';
import 'package:hostel_management/features/room/domain/entities/room_status.dart';
import 'package:hostel_management/features/room/data/models/room_model.dart';
import 'package:hostel_management/features/tenant/data/repositories/tenant_management_repository_impl.dart';
import 'package:hostel_management/features/tenant/data/repositories/tenant_repository_impl.dart';
import 'package:hostel_management/features/tenant/domain/entities/tenant_entity.dart';
import 'package:hostel_management/features/tenant/domain/entities/tenant_status.dart';

Future<AppDatabase> _openTestDatabase() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  await AppDatabase.instance.close();
  return AppDatabase.instance;
}

TenantEntity buildTenant({
  int? id,
  int bedId = 1,
  String fullName = 'Alice Smith',
  String phoneNumber = '9876543210',
  String? email = 'alice@example.com',
  TenantStatus status = TenantStatus.active,
}) {
  final now = DateTime.now();
  return TenantEntity(
    id: id,
    bedId: bedId,
    fullName: fullName,
    phoneNumber: phoneNumber,
    email: email,
    checkInDate: now,
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late AppDatabase appDatabase;
  late TenantManagementRepositoryImpl managementRepo;
  late TenantRepositoryImpl tenantRepo;
  late BedRepositoryImpl bedRepo;
  late RoomManagementRepositoryImpl roomManagementRepo;
  late DashboardRepositoryImpl dashboardRepo;

  Future<void> seedDatabase() async {
    final db = await appDatabase.database;
    await db.execute('''
      INSERT OR IGNORE INTO users (id, name, phone, email, role, is_active, created_at)
      VALUES (1, 'Owner', '000', 'o@o.com', 'owner', 1, '2024-01-01T00:00:00.000')
    ''');
    await db.execute('''
      INSERT OR IGNORE INTO hostels (id, name, address, phone, email, owner_name, owner_user_id, created_at, updated_at)
      VALUES (1, 'Test Hostel', 'Address', '000', 'h@h.com', 'Owner', 1, '2024-01-01T00:00:00.000', '2024-01-01T00:00:00.000')
    ''');
    // Room 1 with 2 beds
    await db.execute('''
      INSERT INTO rooms (id, hostel_id, room_number, floor, room_type, number_of_beds, monthly_rent, status, created_at, updated_at)
      VALUES (1, 1, '101', 'G', 'double', 2, 1000, 'vacant', '2024-01-01T00:00:00.000', '2024-01-01T00:00:00.000')
    ''');
    await db.execute('''
      INSERT INTO beds (id, room_id, bed_number, monthly_rent, status, created_at, updated_at)
      VALUES 
        (1, 1, 'B1', 1000, 'vacant', '2024-01-01T00:00:00.000', '2024-01-01T00:00:00.000'),
        (2, 1, 'B2', 1000, 'vacant', '2024-01-01T00:00:00.000', '2024-01-01T00:00:00.000')
    ''');
  }

  Future<RoomStatus> getRoomStatus(int roomId) async {
    final db = await appDatabase.database;
    final res = await db.query('rooms', where: 'id = ?', whereArgs: [roomId]);
    return RoomModel.fromMap(res.first).status;
  }

  setUpAll(() async {
    appDatabase = await _openTestDatabase();
  });

  setUp(() async {
    tenantRepo = TenantRepositoryImpl(appDatabase);
    bedRepo = BedRepositoryImpl(appDatabase);
    roomManagementRepo = RoomManagementRepositoryImpl(appDatabase);
    dashboardRepo = DashboardRepositoryImpl(appDatabase);

    managementRepo = TenantManagementRepositoryImpl(
      appDatabase,
      tenantRepo,
      bedRepo,
      roomManagementRepo,
    );

    final db = await appDatabase.database;
    await db.delete('deposits');
    await db.delete('rent_records');
    await db.delete('stays');
    await db.delete('tenants');
    await db.delete('beds');
    await db.delete('rooms');
    await seedDatabase();
  });

  tearDownAll(() async {
    await appDatabase.close();
  });

  group('assignTenant', () {
    test(
        'creates tenant, marks bed occupied, and updates room to partially_occupied',
        () async {
      final tenant = await managementRepo.assignTenant(buildTenant(bedId: 1));
      expect(tenant.id, isNotNull);

      // Bed is occupied
      final bed = await bedRepo.getBedById(1);
      expect(bed!.status, BedStatus.occupied);

      // Room is partially occupied
      expect(await getRoomStatus(1), RoomStatus.partiallyOccupied);
    });

    test('fills the room and marks room as occupied', () async {
      await managementRepo.assignTenant(
          buildTenant(bedId: 1, phoneNumber: '111', email: '1@a.com'));
      await managementRepo.assignTenant(
          buildTenant(bedId: 2, phoneNumber: '222', email: '2@a.com'));

      expect(await getRoomStatus(1), RoomStatus.occupied);
    });

    test('rolls back if phone is duplicate', () async {
      await managementRepo
          .assignTenant(buildTenant(bedId: 1, phoneNumber: '9999999999'));

      await expectLater(
        managementRepo
            .assignTenant(buildTenant(bedId: 2, phoneNumber: '9999999999')),
        throwsStateError,
      );

      // Bed 2 should still be vacant
      final bed = await bedRepo.getBedById(2);
      expect(bed!.status, BedStatus.vacant);
    });

    test('rejects occupied bed', () async {
      await managementRepo.assignTenant(
          buildTenant(bedId: 1, phoneNumber: '111', email: '1@a.com'));

      await expectLater(
        managementRepo.assignTenant(
            buildTenant(bedId: 1, phoneNumber: '222', email: '2@a.com')),
        throwsStateError,
      );
    });

    test('rejects inactive bed', () async {
      final db = await appDatabase.database;
      await db.update('beds', {'status': 'inactive'},
          where: 'id = ?', whereArgs: [1]);

      await expectLater(
        managementRepo.assignTenant(buildTenant(bedId: 1)),
        throwsStateError,
      );
    });
  });

  group('checkOutTenant', () {
    test('marks tenant checkedOut, bed vacant, and updates room status',
        () async {
      final t1 = await managementRepo.assignTenant(
          buildTenant(bedId: 1, phoneNumber: '111', email: '1@a.com'));
      await managementRepo.assignTenant(
          buildTenant(bedId: 2, phoneNumber: '222', email: '2@a.com'));

      expect(await getRoomStatus(1), RoomStatus.occupied);

      final out = await managementRepo.checkOutTenant(t1.id!, bedId: 1);

      expect(out.status, TenantStatus.checkedOut);
      expect(out.bedId, isNull);
      expect(out.checkOutDate, isNotNull);

      final stored = await tenantRepo.getTenantById(t1.id!);
      expect(stored!.bedId, isNull);

      // Bed is vacant
      final bed = await bedRepo.getBedById(1);
      expect(bed!.status, BedStatus.vacant);

      // Room is now partially occupied
      expect(await getRoomStatus(1), RoomStatus.partiallyOccupied);

      final summary = await dashboardRepo.getSummary(1);
      expect(summary.activeTenants, 1);
      expect(summary.checkedOutTenants, 1);
    });

    test('releases a checked-out bed for a new tenant', () async {
      final first = await managementRepo.assignTenant(
        buildTenant(bedId: 1, phoneNumber: '111', email: '1@a.com'),
      );

      await managementRepo.checkOutTenant(first.id!, bedId: 1);

      final second = await managementRepo.assignTenant(
        buildTenant(bedId: 1, phoneNumber: '222', email: '2@a.com'),
      );

      expect(second.bedId, 1);
      expect((await tenantRepo.getTenantById(first.id!))!.bedId, isNull);
      expect((await bedRepo.getBedById(1))!.status, BedStatus.occupied);
      expect(await getRoomStatus(1), RoomStatus.partiallyOccupied);
    });

    test('preserves checkout history while the replacement tenant can transfer',
        () async {
      final first = await managementRepo.assignTenant(
        buildTenant(bedId: 1, phoneNumber: '111', email: '1@a.com'),
      );

      await managementRepo.checkOutTenant(first.id!, bedId: 1);
      final replacement = await managementRepo.assignTenant(
        buildTenant(bedId: 1, phoneNumber: '222', email: '2@a.com'),
      );

      final transferred = await managementRepo.transferTenant(
        replacement.id!,
        oldBedId: 1,
        newBedId: 2,
      );

      final historical = await tenantRepo.getTenantById(first.id!);
      expect(historical!.status, TenantStatus.checkedOut);
      expect(historical.bedId, isNull);
      expect(historical.checkOutDate, isNotNull);
      expect(transferred.bedId, 2);
      expect((await bedRepo.getBedById(1))!.status, BedStatus.vacant);
      expect((await bedRepo.getBedById(2))!.status, BedStatus.occupied);
      expect(await getRoomStatus(1), RoomStatus.partiallyOccupied);
    });
  });

  group('deleteTenant', () {
    test('deletes tenant, marks bed vacant, and recalculates room', () async {
      final t1 = await managementRepo.assignTenant(buildTenant(bedId: 1));

      expect(await getRoomStatus(1), RoomStatus.partiallyOccupied);

      await managementRepo.deleteTenant(t1.id!, bedId: 1);

      final fetched = await tenantRepo.getTenantById(t1.id!);
      expect(fetched, isNull);

      final bed = await bedRepo.getBedById(1);
      expect(bed!.status, BedStatus.vacant);
      expect(await getRoomStatus(1), RoomStatus.vacant);
    });
  });

  group('transferTenant', () {
    test('transfers tenant, syncs both beds and rooms', () async {
      // Setup room 2
      final db = await appDatabase.database;
      await db.execute('''
        INSERT INTO rooms (id, hostel_id, room_number, floor, room_type, number_of_beds, monthly_rent, status, created_at, updated_at)
        VALUES (2, 1, '102', 'G', 'double', 2, 1000, 'vacant', '2024-01-01T00:00:00.000', '2024-01-01T00:00:00.000')
      ''');
      await db.execute('''
        INSERT INTO beds (id, room_id, bed_number, monthly_rent, status, created_at, updated_at)
        VALUES 
          (3, 2, 'B3', 1000, 'vacant', '2024-01-01T00:00:00.000', '2024-01-01T00:00:00.000'),
          (4, 2, 'B4', 1000, 'vacant', '2024-01-01T00:00:00.000', '2024-01-01T00:00:00.000')
      ''');

      final t1 = await managementRepo.assignTenant(buildTenant(bedId: 1));
      
      expect(await getRoomStatus(1), RoomStatus.partiallyOccupied);
      expect(await getRoomStatus(2), RoomStatus.vacant);

      final transferred = await managementRepo.transferTenant(t1.id!, oldBedId: 1, newBedId: 3);

      expect(transferred.bedId, 3);
      
      final oldBed = await bedRepo.getBedById(1);
      expect(oldBed!.status, BedStatus.vacant);

      final newBed = await bedRepo.getBedById(3);
      expect(newBed!.status, BedStatus.occupied);

      expect(await getRoomStatus(1), RoomStatus.vacant);
      expect(await getRoomStatus(2), RoomStatus.partiallyOccupied);
    });

    test('rejects transfer to same bed', () async {
      final t1 = await managementRepo.assignTenant(buildTenant(bedId: 1));

      await expectLater(
        managementRepo.transferTenant(t1.id!, oldBedId: 1, newBedId: 1),
        throwsStateError,
      );
    });

    test('rejects transfer to occupied bed', () async {
      final t1 = await managementRepo.assignTenant(buildTenant(bedId: 1, phoneNumber: '111', email: '1@a.com'));
      await managementRepo.assignTenant(buildTenant(bedId: 2, phoneNumber: '222', email: '2@a.com'));

      await expectLater(
        managementRepo.transferTenant(t1.id!, oldBedId: 1, newBedId: 2),
        throwsStateError,
      );
    });

    test('rejects transfer to inactive bed', () async {
      final t1 = await managementRepo.assignTenant(buildTenant(bedId: 1));
      
      final db = await appDatabase.database;
      await db.update('beds', {'status': 'inactive'}, where: 'id = ?', whereArgs: [2]);

      await expectLater(
        managementRepo.transferTenant(t1.id!, oldBedId: 1, newBedId: 2),
        throwsStateError,
      );
    });
  });
}
