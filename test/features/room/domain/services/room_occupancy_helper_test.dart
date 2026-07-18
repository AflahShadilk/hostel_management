import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_management/features/room/domain/services/room_occupancy_helper.dart';
import 'package:hostel_management/features/room/domain/entities/room_entity.dart';
import 'package:hostel_management/features/room/domain/entities/room_status.dart';
import 'package:hostel_management/features/room/domain/entities/room_type.dart';
import 'package:hostel_management/features/room/domain/entities/bed_entity.dart';
import 'package:hostel_management/features/room/domain/entities/bed_status.dart';

void main() {
  final now = DateTime.now();

  RoomEntity createRoom({RoomStatus status = RoomStatus.vacant}) {
    return RoomEntity(
      id: 1,
      hostelId: 10,
      roomNumber: '101',
      floor: '1',
      roomType: RoomType.double,
      numberOfBeds: 2,
      monthlyRent: 500.0,
      status: status,
      createdAt: now,
      updatedAt: now,
    );
  }

  BedEntity createBed(String number, BedStatus status) {
    return BedEntity(
      id: 1,
      roomId: 1,
      bedNumber: number,
      status: status,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('RoomOccupancyHelper', () {
    test('All vacant -> vacant', () {
      final room = createRoom();
      final beds = [
        createBed('B1', BedStatus.vacant),
        createBed('B2', BedStatus.vacant),
      ];

      final status =
          RoomOccupancyHelper.calculateRoomStatus(room: room, beds: beds);
      expect(status, RoomStatus.vacant);
    });

    test('One occupied, one vacant -> partiallyOccupied', () {
      final room = createRoom();
      final beds = [
        createBed('B1', BedStatus.occupied),
        createBed('B2', BedStatus.vacant),
      ];

      final status =
          RoomOccupancyHelper.calculateRoomStatus(room: room, beds: beds);
      expect(status, RoomStatus.partiallyOccupied);
    });

    test('All usable occupied -> occupied', () {
      final room = createRoom();
      final beds = [
        createBed('B1', BedStatus.occupied),
        createBed('B2', BedStatus.occupied),
      ];

      final status =
          RoomOccupancyHelper.calculateRoomStatus(room: room, beds: beds);
      expect(status, RoomStatus.occupied);
    });

    test('Occupied + inactive -> occupied if all usable beds are occupied', () {
      final room = createRoom();
      final beds = [
        createBed('B1', BedStatus.occupied),
        createBed('B2', BedStatus.inactive),
      ];

      final status =
          RoomOccupancyHelper.calculateRoomStatus(room: room, beds: beds);
      expect(status, RoomStatus.occupied);
    });

    test('Vacant + inactive -> vacant', () {
      final room = createRoom();
      final beds = [
        createBed('B1', BedStatus.vacant),
        createBed('B2', BedStatus.inactive),
      ];

      final status =
          RoomOccupancyHelper.calculateRoomStatus(room: room, beds: beds);
      expect(status, RoomStatus.vacant);
    });

    test('Occupied + vacant + inactive -> partiallyOccupied', () {
      final room = createRoom();
      final beds = [
        createBed('B1', BedStatus.occupied),
        createBed('B2', BedStatus.vacant),
        createBed('B3', BedStatus.inactive),
      ];

      final status =
          RoomOccupancyHelper.calculateRoomStatus(room: room, beds: beds);
      expect(status, RoomStatus.partiallyOccupied);
    });

    test('No usable beds -> vacant', () {
      final room = createRoom();
      final beds = [
        createBed('B1', BedStatus.inactive),
        createBed('B2', BedStatus.inactive),
      ];

      final status =
          RoomOccupancyHelper.calculateRoomStatus(room: room, beds: beds);
      expect(status, RoomStatus.vacant);
    });

    test('Existing Room inactive -> inactive (preserves)', () {
      final room = createRoom(status: RoomStatus.inactive);
      final beds = [
        createBed('B1', BedStatus.vacant),
      ];

      final status =
          RoomOccupancyHelper.calculateRoomStatus(room: room, beds: beds);
      expect(status, RoomStatus.inactive);
    });
  });
}
