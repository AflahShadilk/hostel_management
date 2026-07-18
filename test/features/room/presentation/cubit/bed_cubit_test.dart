import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_management/features/room/domain/entities/bed_entity.dart';
import 'package:hostel_management/features/room/domain/entities/bed_status.dart';
import 'package:hostel_management/features/room/domain/entities/room_entity.dart';
import 'package:hostel_management/features/room/domain/entities/room_status.dart';
import 'package:hostel_management/features/room/domain/entities/room_type.dart';
import 'package:hostel_management/features/room/domain/repositories/bed_repository.dart';
import 'package:hostel_management/features/room/domain/repositories/room_repository.dart';
import 'package:hostel_management/features/room/presentation/cubit/bed_cubit.dart';
import 'package:hostel_management/features/room/presentation/cubit/bed_operation_status.dart';

class FakeBedRepository implements BedRepository {
  List<BedEntity> beds = [];
  bool shouldThrow = false;

  @override
  Future<bool> bedNumberExists(
      {required int roomId,
      required String bedNumber,
      int? excludeBedId}) async {
    return false;
  }

  @override
  Future<int> countBedsByRoomId(int roomId) async => beds.length;

  @override
  Future<int> countBedsByStatus(
          {required int roomId, required BedStatus status}) async =>
      0;

  @override
  Future<BedEntity> createBed(BedEntity bed) async => bed;

  @override
  Future<void> createBeds(List<BedEntity> beds) async {}

  @override
  Future<void> deleteBed(int id) async {}

  @override
  Future<BedEntity?> getBedById(int id) async =>
      beds.where((b) => b.id == id).firstOrNull;

  @override
  Future<List<BedEntity>> getBedsByRoomId(int roomId) async {
    if (shouldThrow) throw Exception('Error');
    return beds.where((b) => b.roomId == roomId).toList();
  }

  @override
  Future<List<BedEntity>> getVacantBedsByRoomId(int roomId) async {
    if (shouldThrow) throw Exception('Error');
    return beds
        .where((b) => b.roomId == roomId && b.status == BedStatus.vacant)
        .toList();
  }

  @override
  Future<void> updateBed(BedEntity bed) async {
    if (shouldThrow) throw Exception('Error');
    final index = beds.indexWhere((b) => b.id == bed.id);
    if (index == -1) throw StateError('Not found');
    beds[index] = bed;
  }
}

class FakeRoomRepositoryForBed implements RoomRepository {
  RoomEntity? room;
  RoomEntity? lastUpdatedRoom;

  @override
  Future<RoomEntity> createRoom(RoomEntity room) async =>
      throw UnimplementedError();
  @override
  Future<void> deleteRoom(int id) async {}
  @override
  Future<RoomEntity?> getRoomById(int id) async => room;
  @override
  Future<RoomEntity?> getRoomByNumber(
          {required int hostelId, required String roomNumber}) async =>
      null;
  @override
  Future<List<RoomEntity>> getRoomsByHostelId(int hostelId) async => [];
  @override
  Future<bool> roomNumberExists(
          {required int hostelId,
          required String roomNumber,
          int? excludeRoomId}) async =>
      false;
  @override
  Future<void> updateRoom(RoomEntity updatedRoom) async {
    lastUpdatedRoom = updatedRoom;
    room = updatedRoom;
  }
}

void main() {
  late FakeBedRepository fakeBedRepository;
  late FakeRoomRepositoryForBed fakeRoomRepository;
  late BedCubit cubit;

  final now = DateTime.now();

  setUp(() {
    fakeBedRepository = FakeBedRepository();
    fakeRoomRepository = FakeRoomRepositoryForBed();
    cubit = BedCubit(fakeBedRepository, fakeRoomRepository);
  });

  tearDown(() {
    cubit.close();
  });

  group('BedCubit loadBeds', () {
    test('loadBeds success', () async {
      final bed = BedEntity(
          id: 1,
          roomId: 1,
          bedNumber: 'B1',
          status: BedStatus.vacant,
          createdAt: now,
          updatedAt: now);
      fakeBedRepository.beds.add(bed);

      await cubit.loadBeds(1);

      expect(cubit.state.status, BedOperationStatus.loaded);
      expect(cubit.state.beds, [bed]);
    });

    test('loadBeds failure', () async {
      fakeBedRepository.shouldThrow = true;
      await cubit.loadBeds(1);
      expect(cubit.state.status, BedOperationStatus.failure);
    });
  });

  group('BedCubit loadVacantBeds', () {
    test('loadVacantBeds uses vacant query', () async {
      final bed1 = BedEntity(
          id: 1,
          roomId: 1,
          bedNumber: 'B1',
          status: BedStatus.vacant,
          createdAt: now,
          updatedAt: now);
      final bed2 = BedEntity(
          id: 2,
          roomId: 1,
          bedNumber: 'B2',
          status: BedStatus.occupied,
          createdAt: now,
          updatedAt: now);
      fakeBedRepository.beds.addAll([bed1, bed2]);

      await cubit.loadVacantBeds(1);

      expect(cubit.state.status, BedOperationStatus.loaded);
      expect(cubit.state.vacantBeds, [bed1]);
    });
  });

  group('BedCubit updateBedStatus', () {
    test('updateBedStatus success and syncs Room occupancy', () async {
      final bed1 = BedEntity(
          id: 1,
          roomId: 1,
          bedNumber: 'B1',
          status: BedStatus.vacant,
          createdAt: now,
          updatedAt: now);
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

      fakeBedRepository.beds.add(bed1);
      fakeRoomRepository.room = room;

      await cubit.updateBedStatus(bed: bed1, status: BedStatus.occupied);

      expect(cubit.state.status, BedOperationStatus.updated);
      expect(cubit.state.beds.first.status, BedStatus.occupied);
      expect(fakeRoomRepository.lastUpdatedRoom?.status,
          RoomStatus.occupied); // because all usable beds (1) are occupied
    });
  });
}
