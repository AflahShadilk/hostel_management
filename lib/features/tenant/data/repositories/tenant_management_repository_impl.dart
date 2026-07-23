import '../../../../core/database/app_database.dart';
import '../../../room/data/datasources/room_local_schema.dart';
import '../../../room/domain/entities/bed_status.dart';
import '../../../room/domain/repositories/bed_repository.dart';
import '../../../room/domain/repositories/room_repository.dart';
import '../../../room/domain/repositories/room_management_repository.dart';
import '../../../rent/domain/utils/rent_calculator.dart';
import '../../domain/entities/tenant_entity.dart';
import '../../domain/entities/tenant_registration_context.dart';
import '../../domain/entities/tenant_status.dart';
import '../../domain/repositories/tenant_management_repository.dart';
import '../../domain/repositories/tenant_repository.dart';
import '../../../rent/data/datasources/rent_local_schema.dart';
import '../../../rent/domain/constants/rent_status_constants.dart';
import '../../../rent/domain/entities/rent_record_entity.dart';
import '../../../rent/domain/entities/stay_entity.dart';
import '../datasources/tenant_local_schema.dart';
import '../models/tenant_model.dart';

class TenantManagementRepositoryImpl implements TenantManagementRepository {
  final AppDatabase _appDatabase;
  final TenantRepository _tenantRepository;
  final BedRepository _bedRepository;
  final RoomRepository _roomRepository;
  final RoomManagementRepository _roomManagementRepository;

  TenantManagementRepositoryImpl(
    this._appDatabase,
    this._tenantRepository,
    this._bedRepository,
    this._roomRepository,
    this._roomManagementRepository,
  );

  @override
  Future<TenantRegistrationContext> assignTenant(TenantEntity tenant) async {
    if (tenant.status != TenantStatus.active || tenant.bedId == null) {
      throw ArgumentError('Only active tenants can be assigned to a bed.');
    }

    final bed = await _bedRepository.getBedById(tenant.bedId!);
    if (bed == null) {
      throw StateError('Cannot assign tenant: Bed not found.');
    }
    if (bed.status != BedStatus.vacant) {
      throw StateError('Cannot assign tenant: Bed is not vacant.');
    }
    final room = await _roomRepository.getRoomById(bed.roomId);
    if (room == null) {
      throw StateError('Cannot assign tenant: Room not found.');
    }

    if (await _tenantRepository.phoneExists(tenant.phoneNumber)) {
      throw StateError(
          'A tenant with phone "${tenant.phoneNumber}" already exists.');
    }

    final email = tenant.email?.trim();
    if (email != null &&
        email.isNotEmpty &&
        await _tenantRepository.emailExists(email)) {
      throw StateError('A tenant with email "$email" already exists.');
    }

    final db = await _appDatabase.database;

    return await db.transaction((txn) async {
      final model = TenantModel.fromEntity(tenant);
      final map = model.toMap();
      map[TenantLocalSchema.colHostelId] = room.hostelId;
      map[TenantLocalSchema.colFullName] = tenant.fullName.trim();
      map[TenantLocalSchema.colPhoneNumber] = tenant.phoneNumber.trim();
      map[TenantLocalSchema.colEmail] =
          (email != null && email.isNotEmpty) ? email.toLowerCase() : null;

      final tenantId = await txn.insert(TenantLocalSchema.tableTenants, map);

      // Create initial stay automatically
      final monthlyRent = bed.monthlyRent;
      final dailyRate = (monthlyRent / 30).roundToDouble();
      final now = DateTime.now().toIso8601String();

      final stayMap = {
        'tenant_id': tenantId,
        'room_id': bed.roomId,
        'bed_id': tenant.bedId,
        'check_in_date': tenant.checkInDate.toIso8601String(),
        'expected_checkout_date': tenant.checkOutDate?.toIso8601String(),
        'monthly_rent_snapshot': monthlyRent,
        'daily_rate': dailyRate,
        'status': StayStatus.active,
        'created_at': now,
        'updated_at': now,
      };
      final stayId = await txn.insert(RentLocalSchema.tableStays, stayMap);

      // Create initial rent record (billing period: checkInDate to checkInDate + 1 month - 1 day)
      final checkIn = tenant.checkInDate;
      final periodEndDate =
          DateTime(checkIn.year, checkIn.month + 1, checkIn.day)
              .subtract(const Duration(days: 1));

      final firstMonthRent =
          RentCalculator.calculateFirstMonthRent(monthlyRent, checkIn);

      final rentRecordMap = {
        'stay_id': stayId,
        'start_date': checkIn.toIso8601String(),
        'end_date': periodEndDate.toIso8601String(),
        'generated_at': now,
        'due_date': checkIn.toIso8601String(),
        'amount_due': firstMonthRent,
        'amount_paid': 0.0,
        'status': RentStatus.pending,
        'created_at': now,
        'updated_at': now,
      };
      final rentRecordId = await txn.insert(
        RentLocalSchema.tableRentRecords,
        rentRecordMap,
      );
      await txn.update(
        RoomLocalSchema.tableBeds,
        {
          'status': BedStatus.occupied.databaseValue,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [tenant.bedId],
      );

      await _roomManagementRepository.syncRoomStatus(bed.roomId, txn: txn);

      final registeredTenant = TenantModel(
        id: tenantId,
        bedId: tenant.bedId,
        fullName: map[TenantLocalSchema.colFullName] as String,
        phoneNumber: map[TenantLocalSchema.colPhoneNumber] as String,
        email: map[TenantLocalSchema.colEmail] as String?,
        address: tenant.address,
        checkInDate: tenant.checkInDate,
        checkOutDate: tenant.checkOutDate,
        emergencyContactName: tenant.emergencyContactName,
        emergencyContactPhone: tenant.emergencyContactPhone,
        status: tenant.status,
        createdAt: tenant.createdAt,
        updatedAt: tenant.updatedAt,
      );
      final createdAt = DateTime.parse(now);
      return TenantRegistrationContext(
        tenant: registeredTenant,
        stay: StayEntity(
          id: stayId,
          tenantId: tenantId,
          roomId: bed.roomId,
          bedId: tenant.bedId!,
          checkInDate: tenant.checkInDate,
          expectedCheckoutDate: tenant.checkOutDate,
          monthlyRentSnapshot: monthlyRent,
          dailyRate: dailyRate,
          status: StayStatus.active,
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
        room: room,
        bed: bed,
        initialRentRecord: RentRecordEntity(
          id: rentRecordId,
          stayId: stayId,
          startDate: checkIn,
          endDate: periodEndDate,
          dueDate: checkIn,
          generatedAt: createdAt,
          amountDue: firstMonthRent,
          amountPaid: 0,
          status: RentStatus.pending,
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );
    });
  }

  @override
  Future<TenantEntity> updateTenantDetails(TenantEntity tenant) async {
    final existing = tenant.id == null
        ? null
        : await _tenantRepository.getTenantById(tenant.id!);
    if (existing == null) {
      throw StateError('Tenant update failed: record not found.');
    }
    if (existing.status != tenant.status || existing.bedId != tenant.bedId) {
      throw StateError(
        'Tenant status and bed assignment can only be changed by checkout or transfer.',
      );
    }

    await _tenantRepository.updateTenant(tenant);
    return tenant;
  }

  @override
  Future<void> deleteTenant(int tenantId, {int? bedId}) async {
    final tenant = await _tenantRepository.getTenantById(tenantId);
    if (tenant == null) return;

    final assignedBedId = tenant.bedId;
    if (assignedBedId == null) {
      final db = await _appDatabase.database;
      await db.transaction((txn) async {
        await txn.execute(
          'DELETE FROM ${RentLocalSchema.tableDeposits} WHERE stay_id IN (SELECT id FROM ${RentLocalSchema.tableStays} WHERE tenant_id = ?)',
          [tenantId],
        );
        await txn.execute(
          'DELETE FROM ${RentLocalSchema.tableRentRecords} WHERE stay_id IN (SELECT id FROM ${RentLocalSchema.tableStays} WHERE tenant_id = ?)',
          [tenantId],
        );

        await txn.delete(
          RentLocalSchema.tableStays,
          where: 'tenant_id = ?',
          whereArgs: [tenantId],
        );
        await txn.delete(
          TenantLocalSchema.tableTenants,
          where: 'id = ?',
          whereArgs: [tenantId],
        );
      });
      return;
    }

    if (bedId != null && bedId != assignedBedId) {
      throw StateError('Tenant bed assignment changed. Reload and try again.');
    }

    final bed = await _bedRepository.getBedById(assignedBedId);
    if (bed == null) return;

    final db = await _appDatabase.database;

    await db.transaction((txn) async {
      await txn.execute(
        'DELETE FROM ${RentLocalSchema.tableDeposits} WHERE stay_id IN (SELECT id FROM ${RentLocalSchema.tableStays} WHERE tenant_id = ?)',
        [tenantId],
      );
      await txn.execute(
        'DELETE FROM ${RentLocalSchema.tableRentRecords} WHERE stay_id IN (SELECT id FROM ${RentLocalSchema.tableStays} WHERE tenant_id = ?)',
        [tenantId],
      );

      await txn.delete(
        RentLocalSchema.tableStays,
        where: 'tenant_id = ?',
        whereArgs: [tenantId],
      );

      await txn.delete(
        TenantLocalSchema.tableTenants,
        where: 'id = ?',
        whereArgs: [tenantId],
      );

      await txn.update(
        RoomLocalSchema.tableBeds,
        {
          'status': BedStatus.vacant.databaseValue,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [assignedBedId],
      );

      await _roomManagementRepository.syncRoomStatus(bed.roomId, txn: txn);
    });
  }

  @override
  Future<TenantEntity> checkOutTenant(int tenantId,
      {required int bedId}) async {
    final bed = await _bedRepository.getBedById(bedId);
    if (bed == null) {
      throw StateError('Bed not found.');
    }

    final tenant = await _tenantRepository.getTenantById(tenantId);
    if (tenant == null) {
      throw StateError('Tenant not found.');
    }
    if (tenant.status != TenantStatus.active || tenant.bedId != bedId) {
      throw StateError('Tenant is not assigned to this bed.');
    }

    final db = await _appDatabase.database;

    return await db.transaction((txn) async {
      final now = DateTime.now();

      // Close the active Stay
      await txn.update(
        RentLocalSchema.tableStays,
        {
          'status': StayStatus.checkedOut,
          'check_out_date': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
        where: 'tenant_id = ? AND status = ?',
        whereArgs: [tenantId, StayStatus.active],
      );

      await txn.update(
        TenantLocalSchema.tableTenants,
        {
          TenantLocalSchema.colStatus: TenantStatus.checkedOut.databaseValue,
          TenantLocalSchema.colBedId: null,
          TenantLocalSchema.colCheckOutDate: now.toIso8601String(),
          TenantLocalSchema.colUpdatedAt: now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [tenantId],
      );

      await txn.update(
        RoomLocalSchema.tableBeds,
        {
          'status': BedStatus.vacant.databaseValue,
          'updated_at': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [bedId],
      );

      await _roomManagementRepository.syncRoomStatus(bed.roomId, txn: txn);

      final model = TenantModel.fromEntity(tenant);
      return model.copyWith(
        bedId: null,
        status: TenantStatus.checkedOut,
        checkOutDate: now,
        updatedAt: now,
      );
    });
  }

  @override
  Future<TenantEntity> transferTenant(
    int tenantId, {
    required int oldBedId,
    required int newBedId,
  }) async {
    if (oldBedId == newBedId) {
      throw StateError('Please select a different bed.');
    }

    final newBed = await _bedRepository.getBedById(newBedId);
    if (newBed == null) {
      throw StateError('This bed is no longer available.');
    }
    if (newBed.status != BedStatus.vacant) {
      throw StateError('This bed is no longer available.');
    }

    final oldBed = await _bedRepository.getBedById(oldBedId);
    if (oldBed == null) {
      throw StateError('Original bed not found.');
    }

    final tenant = await _tenantRepository.getTenantById(tenantId);
    if (tenant == null) {
      throw StateError('Tenant not found.');
    }
    if (tenant.status != TenantStatus.active || tenant.bedId != oldBedId) {
      throw StateError('Tenant is not assigned to the original bed.');
    }

    final db = await _appDatabase.database;

    return await db.transaction((txn) async {
      final now = DateTime.now();
      final nowText = now.toIso8601String();

      // Find old stay ID
      final oldStayRows = await txn.query(
        RentLocalSchema.tableStays,
        columns: ['id'],
        where: 'tenant_id = ? AND status = ?',
        whereArgs: [tenantId, StayStatus.active],
        limit: 1,
      );
      if (oldStayRows.isEmpty) throw StateError('Active stay not found.');
      final activeStayId = oldStayRows.first['id'] as int;

      // Update the active stay with the new room and bed
      await txn.update(
        RentLocalSchema.tableStays,
        {
          'room_id': newBed.roomId,
          'bed_id': newBedId,
          'updated_at': nowText,
        },
        where: 'id = ?',
        whereArgs: [activeStayId],
      );

      // Release old bed
      await txn.update(
        RoomLocalSchema.tableBeds,
        {
          'status': BedStatus.vacant.databaseValue,
          'updated_at': nowText,
        },
        where: 'id = ?',
        whereArgs: [oldBedId],
      );

      // Occupy new bed
      await txn.update(
        RoomLocalSchema.tableBeds,
        {
          'status': BedStatus.occupied.databaseValue,
          'updated_at': nowText,
        },
        where: 'id = ?',
        whereArgs: [newBedId],
      );

      // Update tenant
      await txn.update(
        TenantLocalSchema.tableTenants,
        {
          TenantLocalSchema.colBedId: newBedId,
          TenantLocalSchema.colUpdatedAt: now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [tenantId],
      );

      // Sync rooms
      await _roomManagementRepository.syncRoomStatus(oldBed.roomId, txn: txn);
      // If the new bed is in a different room, sync that room too
      if (oldBed.roomId != newBed.roomId) {
        await _roomManagementRepository.syncRoomStatus(newBed.roomId, txn: txn);
      }

      final model = TenantModel.fromEntity(tenant);
      return model.copyWith(
        bedId: newBedId,
        updatedAt: now,
      );
    });
  }
}
