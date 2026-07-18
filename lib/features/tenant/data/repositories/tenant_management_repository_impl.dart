import '../../../../core/database/app_database.dart';
import '../../../room/data/datasources/room_local_schema.dart';
import '../../../room/domain/entities/bed_status.dart';
import '../../../room/domain/repositories/bed_repository.dart';
import '../../../room/domain/repositories/room_management_repository.dart';
import '../../domain/entities/tenant_entity.dart';
import '../../domain/entities/tenant_status.dart';
import '../../domain/repositories/tenant_management_repository.dart';
import '../../domain/repositories/tenant_repository.dart';
import '../datasources/tenant_local_schema.dart';
import '../models/tenant_model.dart';

class TenantManagementRepositoryImpl implements TenantManagementRepository {
  final AppDatabase _appDatabase;
  final TenantRepository _tenantRepository;
  final BedRepository _bedRepository;
  final RoomManagementRepository _roomManagementRepository;

  TenantManagementRepositoryImpl(
    this._appDatabase,
    this._tenantRepository,
    this._bedRepository,
    this._roomManagementRepository,
  );

  @override
  Future<TenantEntity> assignTenant(TenantEntity tenant) async {
    final bed = await _bedRepository.getBedById(tenant.bedId);
    if (bed == null) {
      throw StateError('Cannot assign tenant: Bed not found.');
    }
    if (bed.status != BedStatus.vacant) {
      throw StateError('Cannot assign tenant: Bed is not vacant.');
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
      map[TenantLocalSchema.colFullName] = tenant.fullName.trim();
      map[TenantLocalSchema.colPhoneNumber] = tenant.phoneNumber.trim();
      map[TenantLocalSchema.colEmail] =
          (email != null && email.isNotEmpty) ? email.toLowerCase() : null;

      final tenantId = await txn.insert(TenantLocalSchema.tableTenants, map);

      await txn.update(
        RoomLocalSchema.tableBeds,
        {
          'status': BedStatus.occupied.databaseValue,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [tenant.bedId],
      );

      await _roomManagementRepository.syncRoomStatus(bed.roomId, txn: txn);

      return TenantModel(
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
    });
  }

  @override
  Future<TenantEntity> updateTenantDetails(TenantEntity tenant) async {
    // Only basic tenant details updated, no bed changes, so we can delegate.
    await _tenantRepository.updateTenant(tenant);
    return tenant;
  }

  @override
  Future<void> deleteTenant(int tenantId, {required int bedId}) async {
    final bed = await _bedRepository.getBedById(bedId);
    if (bed == null) return;

    final db = await _appDatabase.database;

    await db.transaction((txn) async {
      await txn.delete(
        TenantLocalSchema.tableTenants,
        where: 'id = ?',
        whereArgs: [tenantId],
      );

      // We don't blindly set it to vacant, but normally it becomes vacant
      // unless there's some other domain rule. We'll set it to vacant.
      await txn.update(
        RoomLocalSchema.tableBeds,
        {
          'status': BedStatus.vacant.databaseValue,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [bedId],
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

    final db = await _appDatabase.database;

    return await db.transaction((txn) async {
      final now = DateTime.now();
      await txn.update(
        TenantLocalSchema.tableTenants,
        {
          TenantLocalSchema.colStatus: TenantStatus.checkedOut.databaseValue,
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
        status: TenantStatus.checkedOut,
        checkOutDate: now,
        updatedAt: now,
      );
    });
  }
}
