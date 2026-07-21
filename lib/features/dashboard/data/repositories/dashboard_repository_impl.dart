import '../../../../core/database/app_database.dart';
import '../../domain/entities/dashboard_summary_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';

import '../../domain/entities/dashboard_activity_entity.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final AppDatabase _database;

  DashboardRepositoryImpl(this._database);

  @override
  Future<DashboardSummaryEntity> getSummary(int hostelId) async {
    final db = await _database.database;

    // Aggregate Rooms
    final roomResult = await db.rawQuery(
      '''
      SELECT 
        COUNT(*) as totalRooms,
        SUM(CASE WHEN status = 'vacant' THEN 1 ELSE 0 END) as vacantRooms,
        SUM(CASE WHEN status = 'partially_occupied' THEN 1 ELSE 0 END) as partiallyOccupiedRooms,
        SUM(CASE WHEN status = 'occupied' THEN 1 ELSE 0 END) as occupiedRooms,
        SUM(CASE WHEN status = 'inactive' THEN 1 ELSE 0 END) as inactiveRooms
      FROM rooms
      WHERE hostel_id = ?
      ''',
      [hostelId],
    );

    // Aggregate Beds by joining with rooms to filter by hostel_id
    final bedResult = await db.rawQuery(
      '''
      SELECT 
        COUNT(*) as totalBeds,
        SUM(CASE WHEN beds.status = 'vacant' THEN 1 ELSE 0 END) as vacantBeds,
        SUM(CASE WHEN beds.status = 'occupied' THEN 1 ELSE 0 END) as occupiedBeds,
        SUM(CASE WHEN beds.status = 'inactive' THEN 1 ELSE 0 END) as inactiveBeds
      FROM beds
      INNER JOIN rooms ON beds.room_id = rooms.id
      WHERE rooms.hostel_id = ?
      ''',
      [hostelId],
    );

    // Aggregate Tenants
    final tenantResult = await db.rawQuery(
      '''
      SELECT 
        COUNT(*) as totalTenants,
        SUM(CASE WHEN tenants.status = 'active' THEN 1 ELSE 0 END) as activeTenants,
        SUM(CASE WHEN tenants.status = 'checked_out' THEN 1 ELSE 0 END) as checkedOutTenants
      FROM tenants
      WHERE tenants.hostel_id = ?
      ''',
      [hostelId],
    );

    // Pending Rent
    final rentResult = await db.rawQuery(
      '''
      SELECT 
        SUM(rent_records.amount_due - rent_records.amount_paid) as pendingRent
      FROM rent_records
      INNER JOIN stays ON rent_records.stay_id = stays.id
      INNER JOIN tenants ON stays.tenant_id = tenants.id
      WHERE tenants.hostel_id = ? AND rent_records.status != 'paid'
      ''',
      [hostelId],
    );

    // Today Checkouts
    final checkoutResult = await db.rawQuery(
      '''
      SELECT 
        COUNT(*) as checkoutCount
      FROM stays
      INNER JOIN tenants ON stays.tenant_id = tenants.id
      WHERE tenants.hostel_id = ? AND date(stays.expected_checkout_date) = date('now')
      ''',
      [hostelId],
    );

    // Recent Activities (UNION)
    final activityResult = await db.rawQuery(
      '''
      SELECT 'Tenant Checked In' as title, 'Room ' || IFNULL(rooms.room_number, 'Unknown') as subtitle, stays.created_at as time, 'tenant_in' as type
      FROM stays
      INNER JOIN tenants ON stays.tenant_id = tenants.id
      LEFT JOIN rooms ON stays.room_id = rooms.id
      WHERE tenants.hostel_id = ? AND stays.status = 'active'
      UNION ALL
      SELECT 'Rent Collected' as title, tenants.full_name || ' paid ' || payments.amount as subtitle, payments.created_at as time, 'payment' as type
      FROM payments
      INNER JOIN rent_records ON payments.rent_record_id = rent_records.id
      INNER JOIN stays ON rent_records.stay_id = stays.id
      INNER JOIN tenants ON stays.tenant_id = tenants.id
      WHERE tenants.hostel_id = ?
      UNION ALL
      SELECT 'Room Added' as title, 'Room ' || rooms.room_number as subtitle, rooms.created_at as time, 'room_add' as type
      FROM rooms
      WHERE rooms.hostel_id = ?
      UNION ALL
      SELECT 'Expense Added' as title, expenses.title || ' (' || expenses.amount || ')' as subtitle, expenses.created_at as time, 'expense' as type
      FROM expenses
      ORDER BY time DESC
      LIMIT 5
      ''',
      [hostelId, hostelId, hostelId],
    );

    List<DashboardActivityEntity> activities = activityResult.map((row) {
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

    final roomRow = roomResult.isNotEmpty ? roomResult.first : {};
    final bedRow = bedResult.isNotEmpty ? bedResult.first : {};
    final tenantRow = tenantResult.isNotEmpty ? tenantResult.first : {};
    final rentRow = rentResult.isNotEmpty ? rentResult.first : {};
    final checkoutRow = checkoutResult.isNotEmpty ? checkoutResult.first : {};

    return DashboardSummaryEntity(
      totalRooms: (roomRow['totalRooms'] as num?)?.toInt() ?? 0,
      vacantRooms: (roomRow['vacantRooms'] as num?)?.toInt() ?? 0,
      partiallyOccupiedRooms:
          (roomRow['partiallyOccupiedRooms'] as num?)?.toInt() ?? 0,
      occupiedRooms: (roomRow['occupiedRooms'] as num?)?.toInt() ?? 0,
      inactiveRooms: (roomRow['inactiveRooms'] as num?)?.toInt() ?? 0,
      totalBeds: (bedRow['totalBeds'] as num?)?.toInt() ?? 0,
      vacantBeds: (bedRow['vacantBeds'] as num?)?.toInt() ?? 0,
      occupiedBeds: (bedRow['occupiedBeds'] as num?)?.toInt() ?? 0,
      inactiveBeds: (bedRow['inactiveBeds'] as num?)?.toInt() ?? 0,
      totalTenants: (tenantRow['totalTenants'] as num?)?.toInt() ?? 0,
      activeTenants: (tenantRow['activeTenants'] as num?)?.toInt() ?? 0,
      checkedOutTenants: (tenantRow['checkedOutTenants'] as num?)?.toInt() ?? 0,
      pendingRent: (rentRow['pendingRent'] as num?)?.toDouble() ?? 0.0,
      todayCheckouts: (checkoutRow['checkoutCount'] as num?)?.toInt() ?? 0,
      recentActivities: activities,
    );
  }
}
