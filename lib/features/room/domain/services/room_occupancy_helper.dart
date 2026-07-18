import '../entities/room_entity.dart';
import '../entities/room_status.dart';
import '../entities/bed_entity.dart';
import '../entities/bed_status.dart';

class RoomOccupancyHelper {
  RoomOccupancyHelper._();

  static RoomStatus calculateRoomStatus({
    required RoomEntity room,
    required List<BedEntity> beds,
  }) {
    // Preserve explicitly inactive room status.
    if (room.status == RoomStatus.inactive) {
      return RoomStatus.inactive;
    }

    final usableBeds =
        beds.where((b) => b.status != BedStatus.inactive).toList();
    final occupiedBeds =
        usableBeds.where((b) => b.status == BedStatus.occupied).toList();

    if (usableBeds.isEmpty) {
      return RoomStatus.vacant;
    }

    if (occupiedBeds.isEmpty) {
      return RoomStatus.vacant;
    }

    if (occupiedBeds.length < usableBeds.length) {
      return RoomStatus.partiallyOccupied;
    }

    // occupiedBeds.length == usableBeds.length
    return RoomStatus.occupied;
  }
}
