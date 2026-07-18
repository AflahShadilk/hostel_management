import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/bed_entity.dart';
import '../../domain/entities/bed_status.dart';
import '../../domain/repositories/bed_repository.dart';
import '../datasources/room_local_schema.dart';
import '../models/bed_model.dart';

class BedRepositoryImpl implements BedRepository {
  final AppDatabase _appDatabase;

  BedRepositoryImpl(this._appDatabase);

  @override
  Future<BedEntity> createBed(BedEntity bed) async {
    final db = await _appDatabase.database;
    final bedModel = BedModel.fromEntity(bed);

    final normalizedMap = bedModel.toMap();
    normalizedMap['bed_number'] = bed.bedNumber.trim();

    final id = await db.insert(RoomLocalSchema.tableBeds, normalizedMap);

    return BedModel(
      id: id,
      roomId: bedModel.roomId,
      bedNumber: normalizedMap['bed_number'] as String,
      status: bedModel.status,
      createdAt: bedModel.createdAt,
      updatedAt: bedModel.updatedAt,
    );
  }

  @override
  Future<void> createBeds(List<BedEntity> beds) async {
    if (beds.isEmpty) return;

    final db = await _appDatabase.database;

    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final bed in beds) {
        final bedModel = BedModel.fromEntity(bed);
        final normalizedMap = bedModel.toMap();
        normalizedMap['bed_number'] = bed.bedNumber.trim();
        batch.insert(RoomLocalSchema.tableBeds, normalizedMap);
      }
      await batch.commit(noResult: true);
    });
  }

  @override
  Future<BedEntity?> getBedById(int id) async {
    final db = await _appDatabase.database;
    final results = await db.query(
      RoomLocalSchema.tableBeds,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return BedModel.fromMap(results.first);
  }

  @override
  Future<List<BedEntity>> getBedsByRoomId(int roomId) async {
    final db = await _appDatabase.database;
    final results = await db.query(
      RoomLocalSchema.tableBeds,
      where: 'room_id = ?',
      whereArgs: [roomId],
      orderBy: 'bed_number COLLATE NOCASE ASC',
    );

    return results.map((e) => BedModel.fromMap(e)).toList();
  }

  @override
  Future<List<BedEntity>> getVacantBedsByRoomId(int roomId) async {
    final db = await _appDatabase.database;
    final results = await db.query(
      RoomLocalSchema.tableBeds,
      where: 'room_id = ? AND status = ?',
      whereArgs: [roomId, BedStatus.vacant.databaseValue],
      orderBy: 'bed_number COLLATE NOCASE ASC',
    );

    return results.map((e) => BedModel.fromMap(e)).toList();
  }

  @override
  Future<bool> bedNumberExists({
    required int roomId,
    required String bedNumber,
    int? excludeBedId,
  }) async {
    final db = await _appDatabase.database;

    String whereClause = 'room_id = ? AND bed_number = ?';
    List<Object?> whereArgs = [roomId, bedNumber.trim()];

    if (excludeBedId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeBedId);
    }

    final results = await db.query(
      RoomLocalSchema.tableBeds,
      columns: ['1'],
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );

    return results.isNotEmpty;
  }

  @override
  Future<void> updateBed(BedEntity bed) async {
    if (bed.id == null) {
      throw StateError('Cannot update a bed without an ID.');
    }

    final db = await _appDatabase.database;
    final bedModel = BedModel.fromEntity(bed);

    final normalizedMap = bedModel.toMap();
    normalizedMap['bed_number'] = bed.bedNumber.trim();

    final rowsAffected = await db.update(
      RoomLocalSchema.tableBeds,
      normalizedMap,
      where: 'id = ?',
      whereArgs: [bed.id],
    );

    if (rowsAffected == 0) {
      throw StateError('Bed update failed: ID not found.');
    }
  }

  @override
  Future<void> deleteBed(int id) async {
    final db = await _appDatabase.database;
    await db.delete(
      RoomLocalSchema.tableBeds,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<int> countBedsByRoomId(int roomId) async {
    final db = await _appDatabase.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM ${RoomLocalSchema.tableBeds} WHERE room_id = ?',
      [roomId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<int> countBedsByStatus({
    required int roomId,
    required BedStatus status,
  }) async {
    final db = await _appDatabase.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM ${RoomLocalSchema.tableBeds} WHERE room_id = ? AND status = ?',
      [roomId, status.databaseValue],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
