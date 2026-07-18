import '../../../../core/database/app_database.dart';
import '../../domain/entities/room_entity.dart';
import '../../domain/entities/bed_status.dart';
import '../../domain/repositories/room_management_repository.dart';
import '../datasources/room_local_schema.dart';
import '../models/room_model.dart';
import '../models/bed_model.dart';

class RoomManagementRepositoryImpl implements RoomManagementRepository {
  final AppDatabase _appDatabase;

  RoomManagementRepositoryImpl(this._appDatabase);

  @override
  Future<RoomEntity> createRoomWithBeds({
    required RoomEntity room,
  }) async {
    final db = await _appDatabase.database;

    return await db.transaction((txn) async {
      // 1. Insert Room
      final roomModel = RoomModel.fromEntity(room);
      final roomMap = roomModel.toMap();
      roomMap['room_number'] = room.roomNumber.trim();
      roomMap['floor'] = room.floor.trim();

      final roomId = await txn.insert(RoomLocalSchema.tableRooms, roomMap);

      // 2. Generate and Insert Beds
      final now = room.createdAt;
      final batch = txn.batch();

      for (int i = 1; i <= room.numberOfBeds; i++) {
        final bedMap = {
          'room_id': roomId,
          'bed_number': 'B$i',
          'status': BedStatus.vacant.databaseValue,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        };
        batch.insert(RoomLocalSchema.tableBeds, bedMap);
      }

      await batch.commit(noResult: true);

      return RoomModel(
        id: roomId,
        hostelId: roomModel.hostelId,
        roomNumber: roomMap['room_number'] as String,
        floor: roomMap['floor'] as String,
        roomType: roomModel.roomType,
        numberOfBeds: roomModel.numberOfBeds,
        monthlyRent: roomModel.monthlyRent,
        status: roomModel.status,
        createdAt: roomModel.createdAt,
        updatedAt: roomModel.updatedAt,
      );
    });
  }

  @override
  Future<RoomEntity> updateRoomWithCapacity({
    required RoomEntity currentRoom,
    required RoomEntity updatedRoom,
  }) async {
    final db = await _appDatabase.database;
    final roomId = updatedRoom.id!;

    return await db.transaction((txn) async {
      final int oldCapacity = currentRoom.numberOfBeds;
      final int newCapacity = updatedRoom.numberOfBeds;
      final now = updatedRoom.updatedAt;

      // 1. Handle Beds if capacity changed
      if (newCapacity > oldCapacity) {
        // Increase capacity
        final batch = txn.batch();
        for (int i = oldCapacity + 1; i <= newCapacity; i++) {
          final bedMap = {
            'room_id': roomId,
            'bed_number': 'B$i',
            'status': BedStatus.vacant.databaseValue,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          };
          batch.insert(RoomLocalSchema.tableBeds, bedMap);
        }
        await batch.commit(noResult: true);
      } else if (newCapacity < oldCapacity) {
        // Decrease capacity
        // Load all beds for the room to check which ones to delete
        final bedsData = await txn.query(
          RoomLocalSchema.tableBeds,
          where: 'room_id = ?',
          whereArgs: [roomId],
        );

        final beds = bedsData.map((e) => BedModel.fromMap(e)).toList();

        // Find auto-generated beds (B<number>)
        final generatedBeds = beds.where((b) {
          if (!b.bedNumber.startsWith('B')) return false;
          final numStr = b.bedNumber.substring(1);
          return int.tryParse(numStr) != null;
        }).toList();

        // Sort descending by number
        generatedBeds.sort((a, b) {
          final numA = int.parse(a.bedNumber.substring(1));
          final numB = int.parse(b.bedNumber.substring(1));
          return numB.compareTo(numA);
        });

        int bedsToRemove = oldCapacity - newCapacity;
        final List<int> idsToDelete = [];

        for (final bed in generatedBeds) {
          if (bedsToRemove == 0) break;

          final bedNum = int.parse(bed.bedNumber.substring(1));
          if (bedNum > newCapacity) {
            if (bed.status != BedStatus.vacant) {
              throw StateError(
                  'Occupied or unavailable beds must be cleared before reducing room capacity.');
            }
            idsToDelete.add(bed.id!);
            bedsToRemove--;
          }
        }

        if (bedsToRemove > 0) {
          throw StateError(
              'Occupied or unavailable beds must be cleared before reducing room capacity.');
        }

        if (idsToDelete.isNotEmpty) {
          final batch = txn.batch();
          for (final id in idsToDelete) {
            batch.delete(RoomLocalSchema.tableBeds,
                where: 'id = ?', whereArgs: [id]);
          }
          await batch.commit(noResult: true);
        }
      }

      // 2. Update Room
      final roomModel = RoomModel.fromEntity(updatedRoom);
      final roomMap = roomModel.toMap();
      roomMap['room_number'] = updatedRoom.roomNumber.trim();
      roomMap['floor'] = updatedRoom.floor.trim();

      final rowsAffected = await txn.update(
        RoomLocalSchema.tableRooms,
        roomMap,
        where: 'id = ?',
        whereArgs: [roomId],
      );

      if (rowsAffected == 0) {
        throw StateError('Room update failed: ID not found.');
      }

      return updatedRoom;
    });
  }
}
