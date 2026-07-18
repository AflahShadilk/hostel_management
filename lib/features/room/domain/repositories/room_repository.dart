import '../entities/room_entity.dart';

abstract interface class RoomRepository {
  Future<RoomEntity> createRoom(RoomEntity room);
  Future<RoomEntity?> getRoomById(int id);
  Future<List<RoomEntity>> getRoomsByHostelId(int hostelId);
  Future<RoomEntity?> getRoomByNumber({
    required int hostelId,
    required String roomNumber,
  });
  Future<bool> roomNumberExists({
    required int hostelId,
    required String roomNumber,
    int? excludeRoomId,
  });
  Future<void> updateRoom(RoomEntity room);
  Future<void> deleteRoom(int id);
}
