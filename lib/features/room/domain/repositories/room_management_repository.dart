import '../entities/room_entity.dart';

abstract interface class RoomManagementRepository {
  Future<RoomEntity> createRoomWithBeds({
    required RoomEntity room,
  });

  Future<RoomEntity> updateRoomWithCapacity({
    required RoomEntity currentRoom,
    required RoomEntity updatedRoom,
  });
}
