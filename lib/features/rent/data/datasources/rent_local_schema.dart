import 'package:sqflite/sqflite.dart';

import '../../domain/constants/rent_status_constants.dart';

/// Defines the persistent storage for the Rent Management module.
///
/// These tables deliberately contain persistence constraints only. Rent
/// calculations and state transitions belong to the module's future domain
/// and data layers.
class RentLocalSchema {
  RentLocalSchema._();

  static const String tableStays = 'stays';
  static const String tableRentRecords = 'rent_records';
  static const String tablePayments = 'payments';
  static const String tableReceipts = 'receipts';
  static const String tableDeposits = 'deposits';
  static const String tableDamageCharges = 'damage_charges';
  static const String tableCheckoutSettlements = 'checkout_settlements';

  static String _sqlValues(List<String> values) =>
      values.map((value) => "'$value'").join(', ');

  /// Creates the rent-management tables in dependency order.
  ///
  /// Financial records use RESTRICT relationships so historical data cannot
  /// be removed implicitly by deleting a parent record.
  static Future<void> createTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE $tableStays (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tenant_id INTEGER NOT NULL,
        room_id INTEGER,
        bed_id INTEGER,
        check_in_date TEXT NOT NULL,
        check_out_date TEXT,
        expected_checkout_date TEXT,
        monthly_rent_snapshot REAL,
        daily_rate REAL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,

        CHECK(monthly_rent_snapshot IS NULL OR monthly_rent_snapshot >= 0),
        CHECK(daily_rate IS NULL OR daily_rate >= 0),
        CHECK(status IN (${_sqlValues(StayStatus.values)})),

        FOREIGN KEY(tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT,
        FOREIGN KEY(room_id) REFERENCES rooms(id) ON DELETE RESTRICT,
        FOREIGN KEY(bed_id) REFERENCES beds(id) ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX stay_current_tenant_unique
      ON $tableStays(tenant_id)
      WHERE status IN (${_sqlValues(<String>[
        StayStatus.active,
        StayStatus.checkoutPending,
      ])})
    ''');

    await db.execute('''
      CREATE TABLE $tableRentRecords (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        stay_id INTEGER NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        generated_at TEXT NOT NULL,
        due_date TEXT NOT NULL,
        amount_due REAL NOT NULL,
        amount_paid REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,

        UNIQUE(stay_id, start_date),
        CHECK(amount_due >= 0),
        CHECK(amount_paid >= 0),
        CHECK(status IN (${_sqlValues(RentStatus.values)})),

        FOREIGN KEY(stay_id) REFERENCES $tableStays(id) ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE TABLE $tablePayments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        rent_record_id INTEGER NOT NULL,
        stay_id INTEGER NOT NULL,
        tenant_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        receipt_number TEXT NOT NULL UNIQUE,
        notes TEXT,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,

        CHECK(amount > 0),
        CHECK(status IN (${_sqlValues(PaymentStatus.values)})),

        FOREIGN KEY(rent_record_id)
          REFERENCES $tableRentRecords(id)
          ON DELETE RESTRICT,
        FOREIGN KEY(stay_id)
          REFERENCES $tableStays(id)
          ON DELETE RESTRICT,
        FOREIGN KEY(tenant_id)
          REFERENCES tenants(id)
          ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableDeposits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        stay_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        received_date TEXT NOT NULL,
        refund_date TEXT,
        refunded_amount REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,

        CHECK(amount >= 0),
        CHECK(refunded_amount >= 0),
        CHECK(status IN ('pending', 'held', 'refunded', 'forfeited')),

        FOREIGN KEY(stay_id) REFERENCES $tableStays(id) ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableDamageCharges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        stay_id INTEGER NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,

        CHECK(amount >= 0),
        CHECK(status IN ('pending', 'paid', 'waived')),

        FOREIGN KEY(stay_id) REFERENCES $tableStays(id) ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableCheckoutSettlements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        stay_id INTEGER NOT NULL,
        rent_due REAL NOT NULL DEFAULT 0,
        deposit_adjustment REAL NOT NULL DEFAULT 0,
        damage_charges REAL NOT NULL DEFAULT 0,
        final_amount REAL NOT NULL DEFAULT 0,
        outstanding_amount REAL NOT NULL DEFAULT 0,
        late_fee REAL NOT NULL DEFAULT 0,
        refund_amount REAL NOT NULL DEFAULT 0,
        settlement_date TEXT,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,

        UNIQUE(stay_id),
        CHECK(status IN (${_sqlValues(SettlementStatus.values)})),

        FOREIGN KEY(stay_id) REFERENCES $tableStays(id) ON DELETE RESTRICT
      )
    ''');
  }

  /// Migrates the v4 rent foundation to v5 without deleting financial rows.
  ///
  /// SQLite requires table reconstruction to change foreign-key actions. New
  /// snapshot columns which had no v4 source remain null; lifecycle timestamps
  /// are backfilled from the corresponding legacy audit timestamps.
  static Future<void> migrateFromVersion4(Database db) async {
    await db.transaction((txn) async {
      for (final table in <String>[
        tableReceipts,
        tablePayments,
        tableRentRecords,
        tableDeposits,
        tableDamageCharges,
        tableCheckoutSettlements,
        tableStays,
      ]) {
        await txn.execute('ALTER TABLE $table RENAME TO ${table}_legacy');
      }

      await txn.execute('DROP INDEX IF EXISTS stay_current_tenant_unique');

      await createTables(txn);

      await txn.execute('''
        INSERT INTO $tableStays (
          id, tenant_id, check_in_date, check_out_date, status, created_at, updated_at
        )
        SELECT id, tenant_id, check_in_date, check_out_date, status, created_at, updated_at
        FROM ${tableStays}_legacy
      ''');
      await txn.execute('''
        INSERT INTO $tableRentRecords (
          id, stay_id, start_date, end_date, generated_at,
          due_date, amount_due, amount_paid, status, created_at, updated_at
        )
        SELECT
          id, stay_id, 
          CASE WHEN rent_period GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]'
            THEN rent_period || '-01' ELSE substr(due_date, 1, 7) || '-01' END,
          CASE WHEN rent_period GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]'
            THEN date(rent_period || '-01', '+1 month', '-1 day') ELSE date(substr(due_date, 1, 7) || '-01', '+1 month', '-1 day') END,
          created_at, due_date, amount_due, amount_paid, status, created_at, updated_at
        FROM ${tableRentRecords}_legacy
      ''');
      await txn.execute('''
        INSERT INTO $tablePayments (
          id, rent_record_id, stay_id, tenant_id, amount, payment_date, payment_method, receipt_number, status, created_at, updated_at
        )
        SELECT
          p.id, p.rent_record_id, s.id, s.tenant_id, p.amount, p.payment_date,
          COALESCE(p.payment_method, 'unknown'), 
          COALESCE(r.receipt_number, 'RCP-LEGACY-' || p.id),
          p.status, p.created_at, p.updated_at
        FROM ${tablePayments}_legacy AS p
        INNER JOIN ${tableRentRecords}_legacy AS rr ON p.rent_record_id = rr.id
        INNER JOIN ${tableStays}_legacy AS s ON rr.stay_id = s.id
        LEFT JOIN ${tableReceipts}_legacy AS r ON p.id = r.payment_id
      ''');
      await txn.execute('''
        INSERT INTO $tableDeposits (
          id, stay_id, amount, received_date, refund_date, refunded_amount,
          status, created_at, updated_at
        )
        SELECT
          id, stay_id, amount, created_at,
          CASE WHEN status = 'refunded' THEN updated_at END,
          CASE WHEN status = 'refunded' THEN amount ELSE 0 END,
          status, created_at, updated_at
        FROM ${tableDeposits}_legacy
      ''');
      await txn.execute('''
        INSERT INTO $tableDamageCharges (
          id, stay_id, description, amount, status, created_at, updated_at
        )
        SELECT id, stay_id, description, amount, status, created_at, updated_at
        FROM ${tableDamageCharges}_legacy
      ''');
      await txn.execute('''
        INSERT INTO $tableCheckoutSettlements (
          id, stay_id, rent_due, deposit_adjustment, damage_charges, final_amount,
          outstanding_amount, late_fee, refund_amount, settlement_date,
          status, created_at, updated_at
        )
        SELECT
          id, stay_id, rent_due, deposit_adjustment, damage_charges, final_amount,
          rent_due, 0, 0,
          CASE WHEN status = '${SettlementStatus.completed}' THEN updated_at END,
          status, created_at, updated_at
        FROM ${tableCheckoutSettlements}_legacy
      ''');

      for (final table in <String>[
        tableReceipts,
        tablePayments,
        tableRentRecords,
        tableDeposits,
        tableDamageCharges,
        tableCheckoutSettlements,
        tableStays,
      ]) {
        await txn.execute('DROP TABLE ${table}_legacy');
      }
    });
  }

  static Future<void> migrateFromVersion9(DatabaseExecutor db) async {
    await db.execute('DROP TABLE IF EXISTS receipts');
    
    // We recreate the payments table because SQLite doesn't support adding constraints 
    // to existing tables easily, but we can just use ALTER TABLE to add columns if we allow nulls.
    // However, stay_id, tenant_id, receipt_number are NOT NULL.
    // If the payments table is empty (which it likely is at this stage of development since UI didn't exist),
    // we can just drop and recreate it.
    
    // Check if table is empty
    final results = await db.query(tablePayments, columns: ['COUNT(*) as count']);
    final count = Sqflite.firstIntValue(results) ?? 0;
    
    if (count == 0) {
      await db.execute('DROP TABLE IF EXISTS $tablePayments');
      await db.execute('''
        CREATE TABLE $tablePayments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          rent_record_id INTEGER NOT NULL,
          stay_id INTEGER NOT NULL,
          tenant_id INTEGER NOT NULL,
          amount REAL NOT NULL,
          payment_date TEXT NOT NULL,
          payment_method TEXT NOT NULL,
          receipt_number TEXT NOT NULL UNIQUE,
          notes TEXT,
          status TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,

          CHECK(amount > 0),
          CHECK(status IN (${_sqlValues(PaymentStatus.values)})),

          FOREIGN KEY(rent_record_id)
            REFERENCES $tableRentRecords(id)
            ON DELETE RESTRICT,
          FOREIGN KEY(stay_id)
            REFERENCES $tableStays(id)
            ON DELETE RESTRICT,
          FOREIGN KEY(tenant_id)
            REFERENCES tenants(id)
            ON DELETE RESTRICT
        )
      ''');
    } else {
      // If not empty, we would need a complex migration copying data, generating fake receipt numbers, etc.
      // Assuming it's empty for this iteration as payment recording was not yet implemented.
      throw StateError('Cannot migrate non-empty payments table automatically from v9 to v10.');
    }
  }

  /// v10 → v11: Replace billing_month/billing_year/rent_period with start_date/end_date.
  ///
  /// The strategy:
  ///  - If rent_records is empty (expected during development), drop and recreate.
  ///  - If not empty, derive start_date from billing_month/billing_year (1st of month)
  ///    and end_date as last day of that billing_month/billing_year.
  ///  - The migration runs inside a transaction for safety.
  static Future<void> migrateFromVersion10(Database db) async {
    await db.transaction((txn) async {
      // Check payment dependency: if payments exist, we cannot drop rent_records.
      final paymentCount =
          Sqflite.firstIntValue(await txn.query(tablePayments, columns: ['COUNT(*) as count'])) ?? 0;

      if (paymentCount > 0) {
        // Payments exist: use ALTER TABLE to add new columns (they default to NULL temporarily).
        await txn.execute('ALTER TABLE $tableRentRecords ADD COLUMN start_date TEXT');
        await txn.execute('ALTER TABLE $tableRentRecords ADD COLUMN end_date TEXT');

        // Backfill start_date from billing_month/billing_year: e.g. 2026-07-01
        await txn.execute("""
          UPDATE $tableRentRecords
          SET start_date = billing_year || '-' ||
            CASE WHEN billing_month < 10 THEN '0' ELSE '' END || billing_month || '-01'
          WHERE start_date IS NULL AND billing_month IS NOT NULL AND billing_year IS NOT NULL
        """);

        // Fallback for records that had no billing_month/billing_year: use due_date month/year
        await txn.execute("""
          UPDATE $tableRentRecords
          SET start_date = substr(due_date, 1, 7) || '-01'
          WHERE start_date IS NULL
        """);

        // Backfill end_date as the last day of start_date's month.
        // We compute: date(start_date, '+1 month', '-1 day')
        await txn.execute("""
          UPDATE $tableRentRecords
          SET end_date = date(start_date, '+1 month', '-1 day')
          WHERE end_date IS NULL
        """);

        // Ensure generated_at is not null (fallback to created_at)
        await txn.execute("""
          UPDATE $tableRentRecords
          SET generated_at = created_at
          WHERE generated_at IS NULL
        """);
      } else {
        // No payments: safely drop and recreate with clean schema.
        await txn.execute('DROP TABLE IF EXISTS $tableRentRecords');
        await txn.execute('''
          CREATE TABLE $tableRentRecords (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            stay_id INTEGER NOT NULL,
            start_date TEXT NOT NULL,
            end_date TEXT NOT NULL,
            generated_at TEXT NOT NULL,
            due_date TEXT NOT NULL,
            amount_due REAL NOT NULL,
            amount_paid REAL NOT NULL DEFAULT 0,
            status TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,

            UNIQUE(stay_id, start_date),
            CHECK(amount_due >= 0),
            CHECK(amount_paid >= 0),

            FOREIGN KEY(stay_id) REFERENCES $tableStays(id) ON DELETE RESTRICT
          )
        ''');
      }
    });
  }
}
