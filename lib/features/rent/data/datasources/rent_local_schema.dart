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
        rent_period TEXT NOT NULL,
        billing_month INTEGER,
        billing_year INTEGER,
        generated_at TEXT,
        due_date TEXT NOT NULL,
        amount_due REAL NOT NULL,
        amount_paid REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,

        UNIQUE(stay_id, rent_period),
        CHECK(billing_month IS NULL OR billing_month BETWEEN 1 AND 12),
        CHECK(billing_year IS NULL OR billing_year >= 0),
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
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,

        CHECK(amount > 0),
        CHECK(status IN (${_sqlValues(PaymentStatus.values)})),

        FOREIGN KEY(rent_record_id)
          REFERENCES $tableRentRecords(id)
          ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableReceipts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        payment_id INTEGER NOT NULL,
        receipt_number TEXT NOT NULL,
        issued_at TEXT NOT NULL,
        payment_amount_snapshot REAL NOT NULL,
        payment_method_snapshot TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,

        UNIQUE(payment_id),
        UNIQUE(receipt_number),

        FOREIGN KEY(payment_id) REFERENCES $tablePayments(id) ON DELETE RESTRICT
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
          id, stay_id, rent_period, billing_month, billing_year, generated_at,
          due_date, amount_due, amount_paid, status, created_at, updated_at
        )
        SELECT
          id, stay_id, rent_period,
          CASE WHEN rent_period GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]'
            THEN CAST(substr(rent_period, 6, 2) AS INTEGER) END,
          CASE WHEN rent_period GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]'
            THEN CAST(substr(rent_period, 1, 4) AS INTEGER) END,
          created_at, due_date, amount_due, amount_paid, status, created_at, updated_at
        FROM ${tableRentRecords}_legacy
      ''');
      await txn.execute('''
        INSERT INTO $tablePayments (
          id, rent_record_id, amount, payment_date, payment_method, status, created_at, updated_at
        )
        SELECT
          id, rent_record_id, amount, payment_date,
          COALESCE(payment_method, 'unknown'), status, created_at, updated_at
        FROM ${tablePayments}_legacy
      ''');
      await txn.execute('''
        INSERT INTO $tableReceipts (
          id, payment_id, receipt_number, issued_at, payment_amount_snapshot,
          payment_method_snapshot, created_at, updated_at
        )
        SELECT
          receipts.id, receipts.payment_id, receipts.receipt_number, receipts.issued_at,
          payments.amount, payments.payment_method, receipts.created_at, receipts.updated_at
        FROM ${tableReceipts}_legacy AS receipts
        INNER JOIN $tablePayments AS payments ON payments.id = receipts.payment_id
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
}
