import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_management/features/room/domain/entities/room_entity.dart';
import 'package:hostel_management/features/room/domain/entities/room_status.dart';
import 'package:hostel_management/features/room/domain/entities/room_type.dart';
import 'package:hostel_management/features/room/domain/repositories/room_management_repository.dart';
import 'package:hostel_management/features/room/domain/repositories/room_repository.dart';
import 'package:hostel_management/features/room/presentation/cubit/room_cubit.dart';
import 'package:hostel_management/features/room/presentation/cubit/room_operation_status.dart';

class FakeRoomRepository implements RoomRepository {
  List<RoomEntity> rooms = [];
  bool shouldThrow = false;

  @override
  Future<RoomEntity> createRoom(RoomEntity room) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteRoom(int id) async {
    if (shouldThrow) throw Exception('Error');
    rooms.removeWhere((r) => r.id == id);
  }

  @override
  Future<RoomEntity?> getRoomById(int id) async {
    if (shouldThrow) throw Exception('Error');
    return rooms.where((r) => r.id == id).firstOrNull;
  }

  @override
  Future<RoomEntity?> getRoomByNumber(
      {required int hostelId, required String roomNumber}) async {
    return rooms
        .where((r) => r.hostelId == hostelId && r.roomNumber == roomNumber)
        .firstOrNull;
  }

  @override
  Future<List<RoomEntity>> getRoomsByHostelId(int hostelId) async {
    if (shouldThrow) throw Exception('Error');
    return rooms.where((r) => r.hostelId == hostelId).toList();
  }

  @override
  Future<bool> roomNumberExists(
      {required int hostelId,
      required String roomNumber,
      int? excludeRoomId}) async {
    if (shouldThrow) throw Exception('Error');
    return rooms.any((r) =>
        r.hostelId == hostelId &&
        r.roomNumber == roomNumber &&
        r.id != excludeRoomId);
  }

  @override
  Future<void> updateRoom(RoomEntity room) async {
    if (shouldThrow) throw Exception('Error');
    final index = rooms.indexWhere((r) => r.id == room.id);
    if (index == -1) throw StateError('Room update failed: ID not found.');
    rooms[index] = room;
  }
}

class FakeRoomManagementRepository implements RoomManagementRepository {
  bool shouldThrow = false;
  int _idCounter = 1;

  @override
  Future<RoomEntity> createRoomWithBeds({required RoomEntity room}) async {
    if (shouldThrow) throw Exception('Error');
    return RoomEntity(
      id: _idCounter++,
      hostelId: room.hostelId,
      roomNumber: room.roomNumber,
      floor: room.floor,
      roomType: room.roomType,
      numberOfBeds: room.numberOfBeds,
      monthlyRent: room.monthlyRent,
      status: room.status,
      createdAt: room.createdAt,
      updatedAt: room.updatedAt,
    );
  }

  @override
  Future<RoomEntity> updateRoomWithCapacity(
      {required RoomEntity currentRoom,
      required RoomEntity updatedRoom}) async {
    if (shouldThrow) throw Exception('Error');
    return updatedRoom;
  }

  @override
  Future<void> syncRoomStatus(int roomId, {Object? txn}) async {
    if (shouldThrow) throw Exception('Error');
  }
}

void main() {
  late FakeRoomRepository fakeRoomRepository;
  late FakeRoomManagementRepository fakeRoomManagementRepository;
  late RoomCubit cubit;

  final now = DateTime.now();

  setUp(() {
    fakeRoomRepository = FakeRoomRepository();
    fakeRoomManagementRepository = FakeRoomManagementRepository();
    cubit = RoomCubit(fakeRoomRepository, fakeRoomManagementRepository);
  });

  tearDown(() {
    cubit.close();
  });

  group('RoomCubit loadRooms', () {
    test('loadRooms success', () async {
      final room = RoomEntity(
          id: 1,
          hostelId: 10,
          roomNumber: '101',
          floor: '1',
          roomType: RoomType.single,
          numberOfBeds: 1,
          monthlyRent: 100,
          status: RoomStatus.vacant,
          createdAt: now,
          updatedAt: now);
      fakeRoomRepository.rooms.add(room);

      await cubit.loadRooms(10);

      expect(cubit.state.status, RoomOperationStatus.loaded);
      expect(cubit.state.rooms, [room]);
    });

    test('loadRooms failure', () async {
      fakeRoomRepository.shouldThrow = true;
      await cubit.loadRooms(10);
      expect(cubit.state.status, RoomOperationStatus.failure);
      expect(cubit.state.errorMessage, 'Unable to load rooms.');
    });

    test('loadRooms invalid hostelId', () async {
      await cubit.loadRooms(-1);
      expect(cubit.state.status, RoomOperationStatus.failure);
      expect(cubit.state.errorMessage, 'Unable to load rooms.');
    });
  });

  group('RoomCubit createRoom', () {
    test('createRoom success', () async {
      await cubit.createRoom(
        hostelId: 10,
        roomNumber: '101',
        floor: '1',
        roomType: RoomType.double,
        numberOfBeds: 2,
        monthlyRent: 500.0,
      );

      expect(cubit.state.status, RoomOperationStatus.created);
      expect(cubit.state.rooms.length, 1);
      expect(cubit.state.rooms.first.roomNumber, '101');
      expect(cubit.state.selectedRoom, isNotNull);
    });

    test('createRoom invalid inputs rejected', () async {
      await cubit.createRoom(
        hostelId: 10,
        roomNumber: '  ',
        floor: '1',
        roomType: RoomType.double,
        numberOfBeds: 2,
        monthlyRent: 500.0,
      );
      expect(cubit.state.status, RoomOperationStatus.failure);
      expect(cubit.state.errorMessage, 'Invalid room data provided.');
    });

    test('createRoom duplicate room number rejected', () async {
      fakeRoomRepository.rooms.add(RoomEntity(
          id: 1,
          hostelId: 10,
          roomNumber: '101',
          floor: '1',
          roomType: RoomType.single,
          numberOfBeds: 1,
          monthlyRent: 100,
          status: RoomStatus.vacant,
          createdAt: now,
          updatedAt: now));

      await cubit.createRoom(
        hostelId: 10,
        roomNumber: '101',
        floor: '1',
        roomType: RoomType.double,
        numberOfBeds: 2,
        monthlyRent: 500.0,
      );

      expect(cubit.state.status, RoomOperationStatus.failure);
      expect(
          cubit.state.errorMessage, 'A room with this number already exists.');
    });

    test('createRoom failure preserves existing rooms', () async {
      fakeRoomManagementRepository.shouldThrow = true;
      final existingRoom = RoomEntity(
          id: 1,
          hostelId: 10,
          roomNumber: '101',
          floor: '1',
          roomType: RoomType.single,
          numberOfBeds: 1,
          monthlyRent: 100,
          status: RoomStatus.vacant,
          createdAt: now,
          updatedAt: now);

      // Seed cubit state
      // Instead of calling private fields, we'll manually emit to set up test state, or just call loadRooms
      fakeRoomRepository.rooms.add(existingRoom);
      await cubit.loadRooms(10);

      await cubit.createRoom(
        hostelId: 10,
        roomNumber: '102',
        floor: '1',
        roomType: RoomType.double,
        numberOfBeds: 2,
        monthlyRent: 500.0,
      );

      expect(cubit.state.status, RoomOperationStatus.failure);
      expect(cubit.state.rooms, [existingRoom]);
    });
  });

  group('RoomCubit updateRoom', () {
    test('updateRoom success (no capacity change)', () async {
      final existingRoom = RoomEntity(
          id: 1,
          hostelId: 10,
          roomNumber: '101',
          floor: '1',
          roomType: RoomType.single,
          numberOfBeds: 1,
          monthlyRent: 100,
          status: RoomStatus.vacant,
          createdAt: now,
          updatedAt: now);
      fakeRoomRepository.rooms.add(existingRoom);
      await cubit.loadRooms(10);

      await cubit.updateRoom(
        currentRoom: existingRoom,
        roomNumber: '102',
        floor: '2',
        roomType: RoomType.double,
        numberOfBeds: 1,
        monthlyRent: 200,
      );

      expect(cubit.state.status, RoomOperationStatus.updated);
      expect(cubit.state.rooms.first.roomNumber, '102');
      expect(fakeRoomRepository.rooms.first.roomNumber, '102');
    });

    test('updateRoom capacity increase success', () async {
      final existingRoom = RoomEntity(
          id: 1,
          hostelId: 10,
          roomNumber: '101',
          floor: '1',
          roomType: RoomType.single,
          numberOfBeds: 1,
          monthlyRent: 100,
          status: RoomStatus.vacant,
          createdAt: now,
          updatedAt: now);
      fakeRoomRepository.rooms.add(existingRoom);
      await cubit.loadRooms(10);

      await cubit.updateRoom(
        currentRoom: existingRoom,
        roomNumber: '101',
        floor: '1',
        roomType: RoomType.single,
        numberOfBeds: 2, // capacity change
        monthlyRent: 100,
      );

      expect(cubit.state.status, RoomOperationStatus.updated);
      expect(cubit.state.rooms.first.numberOfBeds, 2);
    });

    test('updateRoom duplicate rejected', () async {
      final existingRoom1 = RoomEntity(
          id: 1,
          hostelId: 10,
          roomNumber: '101',
          floor: '1',
          roomType: RoomType.single,
          numberOfBeds: 1,
          monthlyRent: 100,
          status: RoomStatus.vacant,
          createdAt: now,
          updatedAt: now);
      final existingRoom2 = RoomEntity(
          id: 2,
          hostelId: 10,
          roomNumber: '102',
          floor: '1',
          roomType: RoomType.single,
          numberOfBeds: 1,
          monthlyRent: 100,
          status: RoomStatus.vacant,
          createdAt: now,
          updatedAt: now);
      fakeRoomRepository.rooms.addAll([existingRoom1, existingRoom2]);
      await cubit.loadRooms(10);

      await cubit.updateRoom(
        currentRoom: existingRoom1,
        roomNumber: '102', // duplicate
        floor: '1',
        roomType: RoomType.single,
        numberOfBeds: 1,
        monthlyRent: 100,
      );

      expect(cubit.state.status, RoomOperationStatus.failure);
      expect(
          cubit.state.errorMessage, 'A room with this number already exists.');
    });
  });

  group('RoomCubit deleteRoom', () {
    test('deleteRoom success', () async {
      final existingRoom = RoomEntity(
          id: 1,
          hostelId: 10,
          roomNumber: '101',
          floor: '1',
          roomType: RoomType.single,
          numberOfBeds: 1,
          monthlyRent: 100,
          status: RoomStatus.vacant,
          createdAt: now,
          updatedAt: now);
      fakeRoomRepository.rooms.add(existingRoom);
      await cubit.loadRooms(10);

      await cubit.deleteRoom(existingRoom);

      expect(cubit.state.status, RoomOperationStatus.deleted);
      expect(cubit.state.rooms, isEmpty);
      expect(fakeRoomRepository.rooms, isEmpty);
    });
  });
}
