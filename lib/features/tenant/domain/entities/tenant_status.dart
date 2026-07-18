/// Represents the occupancy lifecycle of a Tenant record.
///
/// - [active]     – Tenant is currently staying in the hostel.
/// - [checkedOut] – Tenant has departed; record is kept for history.
/// - [inactive]   – Tenant record has been archived / disabled.
enum TenantStatus {
  active('active'),
  checkedOut('checked_out'),
  inactive('inactive');

  final String databaseValue;
  const TenantStatus(this.databaseValue);

  static TenantStatus? fromDatabaseValue(String value) {
    for (final status in TenantStatus.values) {
      if (status.databaseValue == value) return status;
    }
    return null;
  }
}
