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
  static const String colHostelId = 'hostel_id';
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
  static Future<void> createTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE $tableTenants (
        $colId                    INTEGER PRIMARY KEY AUTOINCREMENT,
        $colBedId                 INTEGER,
        $colHostelId              INTEGER,
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

        CHECK($colStatus IN ('active', 'checked_out', 'inactive')),

        FOREIGN KEY($colBedId)
          REFERENCES beds(id)
          ON DELETE CASCADE,

        FOREIGN KEY($colHostelId)
          REFERENCES hostels(id)
          ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX tenant_active_bed_unique
      ON $tableTenants($colBedId)
      WHERE $colStatus = 'active' AND $colBedId IS NOT NULL
    ''');
  }

  /// Replaces the v2 table-level bed uniqueness constraint with an active-only
  /// unique index and clears historical bed references.
  ///
  /// The v2 schema derived a tenant's hostel through bed -> room, so this
  /// migration follows that same relationship while materialising hostel_id.
  /// A checked-out tenant keeps every historical field, including its checkout
  /// date, but no longer holds a bed reference.
  static Future<void> migrateFromVersion2(Database db) async {
    await db.transaction((txn) async {
      await txn.execute('ALTER TABLE $tableTenants RENAME TO tenants_legacy');
      await createTable(txn);
      await txn.execute('''
        INSERT INTO $tableTenants (
          $colId, $colBedId, $colHostelId, $colFullName, $colPhoneNumber, $colEmail,
          $colAddress, $colCheckInDate, $colCheckOutDate,
          $colEmergencyContactName, $colEmergencyContactPhone, $colStatus,
          $colCreatedAt, $colUpdatedAt
        )
        SELECT
          $colId,
          CASE WHEN $colStatus = 'active' THEN $colBedId ELSE NULL END,
          rooms.hostel_id,
          $colFullName, $colPhoneNumber, $colEmail, $colAddress,
          $colCheckInDate, $colCheckOutDate, $colEmergencyContactName,
          $colEmergencyContactPhone, $colStatus, $colCreatedAt, $colUpdatedAt
        FROM tenants_legacy
        LEFT JOIN beds ON beds.id = tenants_legacy.$colBedId
        LEFT JOIN rooms ON rooms.id = beds.room_id
      ''');
      await txn.execute('DROP TABLE tenants_legacy');
    });
  }
}
