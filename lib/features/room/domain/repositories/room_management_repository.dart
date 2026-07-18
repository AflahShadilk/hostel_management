import '../entities/room_entity.dart';

abstract interface class RoomManagementRepository {
  Future<RoomEntity> createRoomWithBeds({
    required RoomEntity room,
  });

  Future<RoomEntity> updateRoomWithCapacity({
    required RoomEntity currentRoom,
    required RoomEntity updatedRoom,
  });

  /// Synchronizes the room status based on its current beds.
  /// An optional SQLite [Transaction] object can be passed as [txn].
  Future<void> syncRoomStatus(int roomId, {Object? txn});
}
