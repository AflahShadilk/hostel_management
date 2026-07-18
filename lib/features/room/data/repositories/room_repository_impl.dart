import '../../../../core/database/app_database.dart';
import '../../domain/entities/room_entity.dart';
import '../../domain/repositories/room_repository.dart';
import '../datasources/room_local_schema.dart';
import '../models/room_model.dart';

class RoomRepositoryImpl implements RoomRepository {
  final AppDatabase _appDatabase;

  RoomRepositoryImpl(this._appDatabase);

  @override
  Future<RoomEntity> createRoom(RoomEntity room) async {
    final db = await _appDatabase.database;
    final roomModel = RoomModel.fromEntity(room);

    // Normalize string fields as requested
    final normalizedMap = roomModel.toMap();
    normalizedMap['room_number'] = room.roomNumber.trim();
    normalizedMap['floor'] = room.floor.trim();

    final id = await db.insert(RoomLocalSchema.tableRooms, normalizedMap);

    return RoomModel(
      id: id,
      hostelId: roomModel.hostelId,
      roomNumber: normalizedMap['room_number'] as String,
      floor: normalizedMap['floor'] as String,
      roomType: roomModel.roomType,
      numberOfBeds: roomModel.numberOfBeds,
      monthlyRent: roomModel.monthlyRent,
      status: roomModel.status,
      createdAt: roomModel.createdAt,
      updatedAt: roomModel.updatedAt,
    );
  }

  @override
  Future<RoomEntity?> getRoomById(int id) async {
    final db = await _appDatabase.database;
    final results = await db.query(
      RoomLocalSchema.tableRooms,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return RoomModel.fromMap(results.first);
  }

  @override
  Future<List<RoomEntity>> getRoomsByHostelId(int hostelId) async {
    final db = await _appDatabase.database;
    final results = await db.query(
      RoomLocalSchema.tableRooms,
      where: 'hostel_id = ?',
      whereArgs: [hostelId],
      orderBy: 'room_number COLLATE NOCASE ASC',
    );

    return results.map((e) => RoomModel.fromMap(e)).toList();
  }

  @override
  Future<RoomEntity?> getRoomByNumber({
    required int hostelId,
    required String roomNumber,
  }) async {
    final db = await _appDatabase.database;
    final results = await db.query(
      RoomLocalSchema.tableRooms,
      where: 'hostel_id = ? AND room_number = ?',
      whereArgs: [hostelId, roomNumber.trim()],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return RoomModel.fromMap(results.first);
  }

  @override
  Future<bool> roomNumberExists({
    required int hostelId,
    required String roomNumber,
    int? excludeRoomId,
  }) async {
    final db = await _appDatabase.database;

    String whereClause = 'hostel_id = ? AND room_number = ?';
    List<Object?> whereArgs = [hostelId, roomNumber.trim()];

    if (excludeRoomId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeRoomId);
    }

    final results = await db.query(
      RoomLocalSchema.tableRooms,
      columns: ['1'],
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );

    return results.isNotEmpty;
  }

  @override
  Future<void> updateRoom(RoomEntity room) async {
    if (room.id == null) {
      throw StateError('Cannot update a room without an ID.');
    }

    final db = await _appDatabase.database;
    final roomModel = RoomModel.fromEntity(room);

    final normalizedMap = roomModel.toMap();
    normalizedMap['room_number'] = room.roomNumber.trim();
    normalizedMap['floor'] = room.floor.trim();

    final rowsAffected = await db.update(
      RoomLocalSchema.tableRooms,
      normalizedMap,
      where: 'id = ?',
      whereArgs: [room.id],
    );

    if (rowsAffected == 0) {
      throw StateError('Room update failed: ID not found.');
    }
  }

  @override
  Future<void> deleteRoom(int id) async {
    final db = await _appDatabase.database;
    await db.delete(
      RoomLocalSchema.tableRooms,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
