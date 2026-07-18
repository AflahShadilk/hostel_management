import '../entities/tenant_entity.dart';

/// Orchestrates cross-domain transactional operations for Tenants.
///
/// Ensures consistency between the Tenant, Bed, and Room aggregates when
/// tenants are assigned, updated, deleted, or checked out.
abstract interface class TenantManagementRepository {
  /// Assigns a new tenant to a bed.
  ///
  /// Transaction flow:
  /// 1. Validates bed exists and is vacant.
  /// 2. Validates phone/email uniqueness.
  /// 3. Creates the tenant record.
  /// 4. Updates BedStatus -> occupied.
  /// 5. Recalculates RoomStatus.
  Future<TenantEntity> assignTenant(TenantEntity tenant);

  /// Updates an existing tenant's personal details.
  ///
  /// This operation does NOT change bed assignments.
  Future<TenantEntity> updateTenantDetails(TenantEntity tenant);

  /// Permanently deletes a tenant.
  ///
  /// Transaction flow:
  /// 1. Deletes the tenant record.
  /// 2. Updates BedStatus -> vacant.
  /// 3. Recalculates RoomStatus.
  Future<void> deleteTenant(int tenantId, {required int bedId});

  /// Checks out an active tenant.
  ///
  /// Transaction flow:
  /// 1. Updates TenantStatus -> checkedOut and sets checkOutDate.
  /// 2. Updates BedStatus -> vacant.
  /// 3. Recalculates RoomStatus.
  Future<TenantEntity> checkOutTenant(int tenantId, {required int bedId});
}
