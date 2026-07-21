import '../../../../../core/database/app_database.dart';
import '../../domain/entities/rent_collection_item_entity.dart';
import '../../domain/repositories/rent_collection_repository.dart';
import '../datasources/rent_local_schema.dart';
import '../models/rent_record_model.dart';
import '../../../room/data/datasources/room_local_schema.dart';
import '../../../tenant/data/datasources/tenant_local_schema.dart';

class RentCollectionRepositoryImpl implements RentCollectionRepository {
  final AppDatabase _appDatabase;

  RentCollectionRepositoryImpl(this._appDatabase);

  @override
  Future<List<RentCollectionItemEntity>> getRentCollectionItems() async {
    final db = await _appDatabase.database;
    final results = await db.rawQuery('''
      SELECT 
        rr.*,
        t.id AS tenant_id,
        t.full_name AS tenant_name,
        r.room_number,
        b.bed_number
      FROM ${RentLocalSchema.tableRentRecords} rr
      JOIN ${RentLocalSchema.tableStays} s ON rr.stay_id = s.id
      JOIN ${TenantLocalSchema.tableTenants} t ON s.tenant_id = t.id
      JOIN ${RoomLocalSchema.tableRooms} r ON s.room_id = r.id
      JOIN ${RoomLocalSchema.tableBeds} b ON s.bed_id = b.id
      WHERE rr.status != 'cancelled'
      ORDER BY rr.due_date ASC
    ''');

    return results.map((row) {
      // The rent record model handles extracting its own fields from the row map.
      final rentRecord = RentRecordModel.fromMap(row).toEntity();
      return RentCollectionItemEntity(
        rentRecord: rentRecord,
        tenantId: row['tenant_id'] as int,
        tenantName: row['tenant_name'] as String,
        roomNumber: row['room_number'] as String,
        bedNumber: row['bed_number'] as String,
      );
    }).toList();
  }
}
