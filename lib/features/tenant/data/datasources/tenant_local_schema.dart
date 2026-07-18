import 'package:sqflite/sqflite.dart';

/// Defines the tenants table DDL and associated constants.
///
/// Tenants are scoped to a Bed. Hostel isolation is achieved through the
/// Bed → Room → Hostel foreign-key chain; no redundant hostel_id column is
/// stored on the tenant itself.
class TenantLocalSchema {
  TenantLocalSchema._();

  static const String tableTenants = 'tenants';

  // ---------------------------------------------------------------------------
  // Column names — referenced by TenantModel to avoid magic strings.
  // ---------------------------------------------------------------------------
  static const String colId = 'id';
  static const String colBedId = 'bed_id';
  static const String colFullName = 'full_name';
  static const String colPhoneNumber = 'phone_number';
  static const String colEmail = 'email';
  static const String colAddress = 'address';
  static const String colCheckInDate = 'check_in_date';
  static const String colCheckOutDate = 'check_out_date';
  static const String colEmergencyContactName = 'emergency_contact_name';
  static const String colEmergencyContactPhone = 'emergency_contact_phone';
  static const String colStatus = 'status';
  static const String colCreatedAt = 'created_at';
  static const String colUpdatedAt = 'updated_at';

  // ---------------------------------------------------------------------------
  // DDL
  // ---------------------------------------------------------------------------

  /// Creates the tenants table.
  ///
  /// This method is called both from [AppDatabase._onCreate] (fresh installs)
  /// and from [AppDatabase._onUpgrade] when upgrading from version 1 → 2.
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableTenants (
        $colId                    INTEGER PRIMARY KEY AUTOINCREMENT,
        $colBedId                 INTEGER NOT NULL,
        $colFullName              TEXT    NOT NULL,
        $colPhoneNumber           TEXT    NOT NULL,
        $colEmail                 TEXT,
        $colAddress               TEXT,
        $colCheckInDate           TEXT    NOT NULL,
        $colCheckOutDate          TEXT,
        $colEmergencyContactName  TEXT,
        $colEmergencyContactPhone TEXT,
        $colStatus                TEXT    NOT NULL,
        $colCreatedAt             TEXT    NOT NULL,
        $colUpdatedAt             TEXT    NOT NULL,

        -- Only one ACTIVE tenant may occupy a given bed at a time.
        -- Checked-out / inactive records are retained for history.
        UNIQUE($colBedId),

        CHECK($colStatus IN ('active', 'checked_out', 'inactive')),

        FOREIGN KEY($colBedId)
          REFERENCES beds(id)
          ON DELETE CASCADE
      )
    ''');
  }
}
