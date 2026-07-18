import '../entities/tenant_entity.dart';

/// Domain contract for all Tenant persistence operations.
///
/// Validation that requires DB state (uniqueness, FK checks) is performed
/// here rather than in the Cubit so the business rules stay in the domain
/// layer and remain testable without Flutter tooling.
abstract interface class TenantRepository {
  /// Persists a new [tenant] and returns its auto-generated database ID.
  ///
  /// Throws [ArgumentError] if:
  /// - [TenantEntity.fullName] is blank.
  /// - [TenantEntity.phoneNumber] is blank.
  /// - [TenantEntity.bedId] is invalid (≤ 0).
  /// - [TenantEntity.checkOutDate] is before [TenantEntity.checkInDate].
  ///
  /// Throws [StateError] if:
  /// - The phone number already belongs to another tenant.
  /// - The email (non-null) already belongs to another tenant.
  Future<int> createTenant(TenantEntity tenant);

  /// Updates an existing tenant.
  ///
  /// Throws [ArgumentError] for the same rules as [createTenant].
  /// Throws [StateError] if the tenant ID is null or not found.
  Future<void> updateTenant(TenantEntity tenant);

  /// Permanently removes the tenant with [tenantId].
  Future<void> deleteTenant(int tenantId);

  /// Returns the tenant with [id], or `null` if not found.
  Future<TenantEntity?> getTenantById(int id);

  /// Returns every tenant record in the database, ordered by full name.
  Future<List<TenantEntity>> getAllTenants();

  /// Full-text search across full_name, phone_number, and email columns.
  ///
  /// Matching is case-insensitive and uses SQLite LIKE patterns, so the query
  /// is never loaded into Dart for filtering.
  Future<List<TenantEntity>> searchTenants(String query);

  /// Returns `true` if any tenant record holds [phone] as their phone number.
  Future<bool> phoneExists(String phone);

  /// Returns `true` if any tenant record holds [email] as their email.
  ///
  /// Always returns `false` for a null or empty [email].
  Future<bool> emailExists(String email);

  /// Returns `true` if the bed with [bedId] currently has an active tenant.
  Future<bool> isBedOccupied(int bedId);
}
