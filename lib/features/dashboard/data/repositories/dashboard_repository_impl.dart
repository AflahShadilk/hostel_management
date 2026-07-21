import '../../../../core/database/app_database.dart';
import '../../domain/entities/dashboard_summary_entity.dart';
import '../../domain/entities/recent_stay_item_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';

import '../../domain/entities/dashboard_activity_entity.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final AppDatabase _database;

  DashboardRepositoryImpl(this._database);

  @override
  Future<DashboardSummaryEntity> getSummary(int hostelId) async {
    final db = await _database.database;

    // ── 1. Rooms ─────────────────────────────────────────────────────────────
    final roomResult = await db.rawQuery(
      '''
      SELECT
        COUNT(*) as totalRooms,
        SUM(CASE WHEN status = 'vacant'             THEN 1 ELSE 0 END) as vacantRooms,
        SUM(CASE WHEN status = 'partially_occupied' THEN 1 ELSE 0 END) as partiallyOccupiedRooms,
        SUM(CASE WHEN status = 'occupied'           THEN 1 ELSE 0 END) as occupiedRooms,
        SUM(CASE WHEN status = 'inactive'           THEN 1 ELSE 0 END) as inactiveRooms
      FROM rooms
      WHERE hostel_id = ?
      ''',
      [hostelId],
    );

    // ── 2. Beds ───────────────────────────────────────────────────────────────
    final bedResult = await db.rawQuery(
      '''
      SELECT
        COUNT(*) as totalBeds,
        SUM(CASE WHEN beds.status = 'vacant'   THEN 1 ELSE 0 END) as vacantBeds,
        SUM(CASE WHEN beds.status = 'occupied' THEN 1 ELSE 0 END) as occupiedBeds,
        SUM(CASE WHEN beds.status = 'inactive' THEN 1 ELSE 0 END) as inactiveBeds
      FROM beds
      INNER JOIN rooms ON beds.room_id = rooms.id
      WHERE rooms.hostel_id = ?
      ''',
      [hostelId],
    );

    // ── 3. Tenants ────────────────────────────────────────────────────────────
    final tenantResult = await db.rawQuery(
      '''
      SELECT
        COUNT(*) as totalTenants,
        SUM(CASE WHEN tenants.status = 'active'      THEN 1 ELSE 0 END) as activeTenants,
        SUM(CASE WHEN tenants.status = 'checked_out' THEN 1 ELSE 0 END) as checkedOutTenants
      FROM tenants
      WHERE tenants.hostel_id = ?
      ''',
      [hostelId],
    );

    // ── 4. Active tenants via stays (source of truth for occupancy) ───────────
    // Active stays are what define "active tenants" per specification.
    final activeStaysResult = await db.rawQuery(
      '''
      SELECT COUNT(*) as activeStays
      FROM stays
      INNER JOIN tenants ON stays.tenant_id = tenants.id
      WHERE tenants.hostel_id = ? AND stays.status = 'active'
      ''',
      [hostelId],
    );

    // ── 5. Pending Rent ───────────────────────────────────────────────────────
    // Sum of (amount_due - amount_paid) for all non-paid rent records.
    final rentResult = await db.rawQuery(
      '''
      SELECT
        COALESCE(SUM(rent_records.amount_due - rent_records.amount_paid), 0) as pendingRent
      FROM rent_records
      INNER JOIN stays     ON rent_records.stay_id   = stays.id
      INNER JOIN tenants   ON stays.tenant_id         = tenants.id
      WHERE tenants.hostel_id = ?
        AND rent_records.status != 'paid'
        AND stays.status = 'active'
      ''',
      [hostelId],
    );

    // ── 6. Monthly Rent Collected (payments for the current month) ────────────
    // Only completed rent payments; excludes deposits, damage charges, refunds.
    final monthlyRentResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(payments.amount), 0) as monthlyRent
      FROM payments
      INNER JOIN stays   ON payments.stay_id   = stays.id
      INNER JOIN tenants ON stays.tenant_id    = tenants.id
      WHERE tenants.hostel_id = ?
        AND payments.status = 'completed'
        AND strftime('%Y-%m', payments.payment_date) = strftime('%Y-%m', 'now')
      ''',
      [hostelId],
    );

    // ── 7. Monthly Expenses ───────────────────────────────────────────────────
    // Sum all expenses (not soft-deleted) with expense_date in current month.
    final monthlyExpensesResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) as monthlyExpenses
      FROM expenses
      WHERE strftime('%Y-%m', expense_date) = strftime('%Y-%m', 'now')
        AND is_deleted = 0
      ''',
    );

    // ── 8. Today's Checkouts ──────────────────────────────────────────────────
    final checkoutResult = await db.rawQuery(
      '''
      SELECT COUNT(*) as checkoutCount
      FROM stays
      INNER JOIN tenants ON stays.tenant_id = tenants.id
      WHERE tenants.hostel_id = ?
        AND date(stays.expected_checkout_date) = date('now')
      ''',
      [hostelId],
    );

    // ── 9. Recent Activities (UNION) ──────────────────────────────────────────
    final activityResult = await db.rawQuery(
      '''
      SELECT 'Tenant Checked In' as title, 'Room ' || IFNULL(rooms.room_number, 'Unknown') as subtitle, stays.created_at as time, 'tenant_in' as type
      FROM stays
      INNER JOIN tenants ON stays.tenant_id = tenants.id
      LEFT JOIN rooms    ON stays.room_id   = rooms.id
      WHERE tenants.hostel_id = ? AND stays.status = 'active'
      UNION ALL
      SELECT 'Rent Collected' as title, tenants.full_name || ' paid ' || payments.amount as subtitle, payments.created_at as time, 'payment' as type
      FROM payments
      INNER JOIN stays   ON payments.stay_id   = stays.id
      INNER JOIN tenants ON stays.tenant_id    = tenants.id
      WHERE tenants.hostel_id = ?
      UNION ALL
      SELECT 'Room Added' as title, 'Room ' || rooms.room_number as subtitle, rooms.created_at as time, 'room_add' as type
      FROM rooms
      WHERE rooms.hostel_id = ?
      UNION ALL
      SELECT 'Expense Added' as title, expenses.title || ' (' || expenses.amount || ')' as subtitle, expenses.created_at as time, 'expense' as type
      FROM expenses
      WHERE expenses.is_deleted = 0
      ORDER BY time DESC
      LIMIT 5
      ''',
      [hostelId, hostelId, hostelId],
    );

    // ── 10. Recent Check-ins (latest 5 active stays) ──────────────────────────
    final recentCheckInsResult = await db.rawQuery(
      '''
      SELECT
        tenants.full_name   as tenantName,
        rooms.room_number   as roomNumber,
        beds.bed_number     as bedNumber,
        stays.check_in_date as date
      FROM stays
      INNER JOIN tenants ON stays.tenant_id = tenants.id
      LEFT  JOIN rooms   ON stays.room_id   = rooms.id
      LEFT  JOIN beds    ON stays.bed_id    = beds.id
      WHERE tenants.hostel_id = ?
        AND stays.status = 'active'
      ORDER BY stays.check_in_date DESC
      LIMIT 5
      ''',
      [hostelId],
    );

    // ── 11. Recent Check-outs (latest 5 completed stays) ─────────────────────
    final recentCheckOutsResult = await db.rawQuery(
      '''
      SELECT
        tenants.full_name       as tenantName,
        rooms.room_number       as roomNumber,
        beds.bed_number         as bedNumber,
        stays.check_out_date    as date
      FROM stays
      INNER JOIN tenants ON stays.tenant_id = tenants.id
      LEFT  JOIN rooms   ON stays.room_id   = rooms.id
      LEFT  JOIN beds    ON stays.bed_id    = beds.id
      WHERE tenants.hostel_id = ?
        AND stays.status = 'checked_out'
        AND stays.check_out_date IS NOT NULL
      ORDER BY stays.check_out_date DESC
      LIMIT 5
      ''',
      [hostelId],
    );

    // ── Map results ───────────────────────────────────────────────────────────

    final activities = activityResult.map((row) {
      DashboardActivityType type = DashboardActivityType.other;
      switch (row['type']) {
        case 'tenant_in':
          type = DashboardActivityType.tenantCheckIn;
          break;
        case 'payment':
          type = DashboardActivityType.rentCollected;
          break;
        case 'room_add':
          type = DashboardActivityType.roomAdded;
          break;
        case 'expense':
          type = DashboardActivityType.expenseAdded;
          break;
      }
      return DashboardActivityEntity(
        title: row['title'] as String? ?? 'Unknown',
        subtitle: row['subtitle'] as String? ?? '',
        time: DateTime.tryParse(row['time'] as String? ?? '') ?? DateTime.now(),
        type: type,
      );
    }).toList();

    final recentCheckIns = recentCheckInsResult.map((row) {
      return RecentStayItemEntity(
        tenantName: row['tenantName'] as String? ?? 'Unknown',
        roomNumber: row['roomNumber'] != null ? 'Room ${row['roomNumber']}' : 'Unknown',
        bedNumber: row['bedNumber'] != null ? 'Bed ${row['bedNumber']}' : 'Unknown',
        date: DateTime.tryParse(row['date'] as String? ?? '') ?? DateTime.now(),
      );
    }).toList();

    final recentCheckOuts = recentCheckOutsResult.map((row) {
      return RecentStayItemEntity(
        tenantName: row['tenantName'] as String? ?? 'Unknown',
        roomNumber: row['roomNumber'] != null ? 'Room ${row['roomNumber']}' : 'Unknown',
        bedNumber: row['bedNumber'] != null ? 'Bed ${row['bedNumber']}' : 'Unknown',
        date: DateTime.tryParse(row['date'] as String? ?? '') ?? DateTime.now(),
      );
    }).toList();

    final roomRow    = roomResult.isNotEmpty    ? roomResult.first    : const <String, Object?>{};
    final bedRow     = bedResult.isNotEmpty     ? bedResult.first     : const <String, Object?>{};
    final tenantRow  = tenantResult.isNotEmpty  ? tenantResult.first  : const <String, Object?>{};
    final stayRow    = activeStaysResult.isNotEmpty ? activeStaysResult.first : const <String, Object?>{};
    final rentRow    = rentResult.isNotEmpty    ? rentResult.first    : const <String, Object?>{};
    final mRentRow   = monthlyRentResult.isNotEmpty ? monthlyRentResult.first : const <String, Object?>{};
    final mExpRow    = monthlyExpensesResult.isNotEmpty ? monthlyExpensesResult.first : const <String, Object?>{};
    final checkoutRow = checkoutResult.isNotEmpty ? checkoutResult.first : const <String, Object?>{};

    return DashboardSummaryEntity(
      totalRooms:              (roomRow['totalRooms']              as num?)?.toInt()    ?? 0,
      vacantRooms:             (roomRow['vacantRooms']             as num?)?.toInt()    ?? 0,
      partiallyOccupiedRooms:  (roomRow['partiallyOccupiedRooms']  as num?)?.toInt()    ?? 0,
      occupiedRooms:           (roomRow['occupiedRooms']           as num?)?.toInt()    ?? 0,
      inactiveRooms:           (roomRow['inactiveRooms']           as num?)?.toInt()    ?? 0,
      totalBeds:               (bedRow['totalBeds']                as num?)?.toInt()    ?? 0,
      vacantBeds:              (bedRow['vacantBeds']               as num?)?.toInt()    ?? 0,
      occupiedBeds:            (bedRow['occupiedBeds']             as num?)?.toInt()    ?? 0,
      inactiveBeds:            (bedRow['inactiveBeds']             as num?)?.toInt()    ?? 0,
      totalTenants:            (tenantRow['totalTenants']          as num?)?.toInt()    ?? 0,
      // Active tenants == active stays (per specification)
      activeTenants:           (stayRow['activeStays']             as num?)?.toInt()    ?? 0,
      checkedOutTenants:       (tenantRow['checkedOutTenants']     as num?)?.toInt()    ?? 0,
      pendingRent:             (rentRow['pendingRent']             as num?)?.toDouble() ?? 0.0,
      monthlyRentCollected:    (mRentRow['monthlyRent']            as num?)?.toDouble() ?? 0.0,
      monthlyExpenses:         (mExpRow['monthlyExpenses']         as num?)?.toDouble() ?? 0.0,
      todayCheckouts:          (checkoutRow['checkoutCount']       as num?)?.toInt()    ?? 0,
      recentActivities: activities,
      recentCheckIns:   recentCheckIns,
      recentCheckOuts:  recentCheckOuts,
    );
  }
}
