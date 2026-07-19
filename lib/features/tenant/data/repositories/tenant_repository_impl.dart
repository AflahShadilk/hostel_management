import '../../../../core/database/app_database.dart';
import '../../domain/entities/tenant_entity.dart';
import '../../domain/entities/tenant_status.dart';
import '../../domain/repositories/tenant_repository.dart';
import '../datasources/tenant_local_schema.dart';
import '../models/tenant_model.dart';

/// SQLite implementation of [TenantRepository].
///
/// All domain validation (blank fields, date ordering, uniqueness) is enforced
/// here so the business rules are unit-testable without any Flutter tooling.
/// No BedStatus or RoomStatus updates are performed; that is Task 02's scope.
class TenantRepositoryImpl implements TenantRepository {
  final AppDatabase _appDatabase;

  TenantRepositoryImpl(this._appDatabase);

  // ---------------------------------------------------------------------------
  // Validation helpers
  // ---------------------------------------------------------------------------

  /// Validates fields that can be checked without a database round-trip.
  ///
  /// Throws [ArgumentError] on the first violation found.
  void _validateFields(TenantEntity tenant) {
    if (tenant.fullName.trim().isEmpty) {
      throw ArgumentError('Tenant full name must not be blank.');
    }
    if (tenant.phoneNumber.trim().isEmpty) {
      throw ArgumentError('Tenant phone number must not be blank.');
    }
    if (tenant.status == TenantStatus.active &&
        (tenant.bedId == null || tenant.bedId! <= 0)) {
      throw ArgumentError('An active tenant must have a valid bed ID.');
    }
    if (tenant.status != TenantStatus.active && tenant.bedId != null) {
      throw ArgumentError('Only active tenants may have an assigned bed.');
    }
    if (tenant.checkOutDate != null &&
        tenant.checkOutDate!.isBefore(tenant.checkInDate)) {
      throw ArgumentError('Check-out date must not be before check-in date.');
    }
  }

  // ---------------------------------------------------------------------------
  // Write operations
  // ---------------------------------------------------------------------------

  @override
  Future<int> createTenant(TenantEntity tenant) async {
    _validateFields(tenant);

    if (await phoneExists(tenant.phoneNumber)) {
      throw StateError(
        'A tenant with phone "${tenant.phoneNumber}" already exists.',
      );
    }

    final email = tenant.email?.trim();
    if (email != null && email.isNotEmpty && await emailExists(email)) {
      throw StateError('A tenant with email "$email" already exists.');
    }

    final db = await _appDatabase.database;
    final model = TenantModel.fromEntity(tenant);
    final map = model.toMap();

    // Normalize text fields before persistence.
    map[TenantLocalSchema.colFullName] = tenant.fullName.trim();
    map[TenantLocalSchema.colPhoneNumber] = tenant.phoneNumber.trim();
    if (email != null && email.isNotEmpty) {
      map[TenantLocalSchema.colEmail] = email.toLowerCase();
    } else {
      map[TenantLocalSchema.colEmail] = null;
    }

    return db.insert(TenantLocalSchema.tableTenants, map);
  }

  @override
  Future<void> updateTenant(TenantEntity tenant) async {
    if (tenant.id == null) {
      throw StateError('Cannot update a tenant without an ID.');
    }

    _validateFields(tenant);

    final db = await _appDatabase.database;

    // Phone uniqueness — exclude this tenant's own record.
    final phoneCheck = await db.query(
      TenantLocalSchema.tableTenants,
      columns: ['1'],
      where:
          '${TenantLocalSchema.colPhoneNumber} = ? AND ${TenantLocalSchema.colId} != ?',
      whereArgs: [tenant.phoneNumber.trim(), tenant.id],
      limit: 1,
    );
    if (phoneCheck.isNotEmpty) {
      throw StateError(
        'A tenant with phone "${tenant.phoneNumber}" already exists.',
      );
    }

    // Email uniqueness (non-null) — exclude this tenant's own record.
    final email = tenant.email?.trim();
    if (email != null && email.isNotEmpty) {
      final emailCheck = await db.query(
        TenantLocalSchema.tableTenants,
        columns: ['1'],
        where:
            '${TenantLocalSchema.colEmail} = ? AND ${TenantLocalSchema.colId} != ?',
        whereArgs: [email.toLowerCase(), tenant.id],
        limit: 1,
      );
      if (emailCheck.isNotEmpty) {
        throw StateError('A tenant with email "$email" already exists.');
      }
    }

    final model = TenantModel.fromEntity(tenant);
    final map = model.toMap();
    map[TenantLocalSchema.colFullName] = tenant.fullName.trim();
    map[TenantLocalSchema.colPhoneNumber] = tenant.phoneNumber.trim();
    map[TenantLocalSchema.colEmail] =
        (email != null && email.isNotEmpty) ? email.toLowerCase() : null;

    final rowsAffected = await db.update(
      TenantLocalSchema.tableTenants,
      map,
      where: '${TenantLocalSchema.colId} = ?',
      whereArgs: [tenant.id],
    );

    if (rowsAffected == 0) {
      throw StateError('Tenant update failed: ID ${tenant.id} not found.');
    }
  }

  @override
  Future<void> deleteTenant(int tenantId) async {
    final db = await _appDatabase.database;
    await db.delete(
      TenantLocalSchema.tableTenants,
      where: '${TenantLocalSchema.colId} = ?',
      whereArgs: [tenantId],
    );
  }

  // ---------------------------------------------------------------------------
  // Read operations
  // ---------------------------------------------------------------------------

  @override
  Future<TenantEntity?> getTenantById(int id) async {
    final db = await _appDatabase.database;
    final results = await db.query(
      TenantLocalSchema.tableTenants,
      where: '${TenantLocalSchema.colId} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return TenantModel.fromMap(results.first);
  }

  @override
  Future<List<TenantEntity>> getAllTenants() async {
    final db = await _appDatabase.database;
    final results = await db.query(
      TenantLocalSchema.tableTenants,
      orderBy: '${TenantLocalSchema.colFullName} COLLATE NOCASE ASC',
    );

    return results.map(TenantModel.fromMap).toList();
  }

  @override
  Future<List<TenantEntity>> searchTenants(String query) async {
    if (query.trim().isEmpty) return getAllTenants();

    final db = await _appDatabase.database;
    final pattern = '%${query.trim()}%';

    final results = await db.query(
      TenantLocalSchema.tableTenants,
      where: '''
        ${TenantLocalSchema.colFullName}    LIKE ? COLLATE NOCASE
        OR ${TenantLocalSchema.colPhoneNumber} LIKE ? COLLATE NOCASE
        OR ${TenantLocalSchema.colEmail}       LIKE ? COLLATE NOCASE
      ''',
      whereArgs: [pattern, pattern, pattern],
      orderBy: '${TenantLocalSchema.colFullName} COLLATE NOCASE ASC',
    );

    return results.map(TenantModel.fromMap).toList();
  }

  // ---------------------------------------------------------------------------
  // Uniqueness checks
  // ---------------------------------------------------------------------------

  @override
  Future<bool> phoneExists(String phone) async {
    if (phone.trim().isEmpty) return false;
    final db = await _appDatabase.database;
    final results = await db.query(
      TenantLocalSchema.tableTenants,
      columns: ['1'],
      where: '${TenantLocalSchema.colPhoneNumber} = ?',
      whereArgs: [phone.trim()],
      limit: 1,
    );
    return results.isNotEmpty;
  }

  @override
  Future<bool> emailExists(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return false;
    final db = await _appDatabase.database;
    final results = await db.query(
      TenantLocalSchema.tableTenants,
      columns: ['1'],
      where: '${TenantLocalSchema.colEmail} = ?',
      whereArgs: [trimmed.toLowerCase()],
      limit: 1,
    );
    return results.isNotEmpty;
  }

  @override
  Future<bool> isBedOccupied(int bedId) async {
    final db = await _appDatabase.database;
    final results = await db.query(
      TenantLocalSchema.tableTenants,
      columns: ['1'],
      where:
          '${TenantLocalSchema.colBedId} = ? AND ${TenantLocalSchema.colStatus} = ?',
      whereArgs: [bedId, TenantStatus.active.databaseValue],
      limit: 1,
    );
    return results.isNotEmpty;
  }
}
