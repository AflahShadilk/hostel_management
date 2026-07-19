import '../../../../core/database/app_database.dart';
import '../../domain/entities/dashboard_summary_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';

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

    // Aggregate Tenants by joining with beds and rooms
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

    final roomRow = roomResult.isNotEmpty ? roomResult.first : {};
    final bedRow = bedResult.isNotEmpty ? bedResult.first : {};
    final tenantRow = tenantResult.isNotEmpty ? tenantResult.first : {};

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
    );
  }
}
