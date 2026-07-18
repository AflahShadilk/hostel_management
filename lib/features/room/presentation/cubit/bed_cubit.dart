import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/bed_entity.dart';
import '../../domain/entities/bed_status.dart';
import '../../domain/entities/room_entity.dart';
import '../../domain/repositories/bed_repository.dart';
import '../../domain/repositories/room_repository.dart';
import '../../domain/services/room_occupancy_helper.dart';
import 'bed_state.dart';
import 'bed_operation_status.dart';

class BedCubit extends Cubit<BedState> {
  final BedRepository _bedRepository;
  final RoomRepository _roomRepository;

  BedCubit(
    this._bedRepository,
    this._roomRepository,
  ) : super(const BedState());

  Future<void> loadBeds(int roomId) async {
    if (roomId <= 0) {
      emit(state.copyWith(
        status: BedOperationStatus.failure,
        errorMessage: () => 'Unable to load beds.',
      ));
      return;
    }

    emit(state.copyWith(
      status: BedOperationStatus.loading,
      errorMessage: () => null,
    ));

    try {
      final beds = await _bedRepository.getBedsByRoomId(roomId);
      emit(state.copyWith(
        status: BedOperationStatus.loaded,
        beds: beds,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: BedOperationStatus.failure,
        errorMessage: () => 'Unable to load beds.',
      ));
    }
  }

  Future<void> loadVacantBeds(int roomId) async {
    if (roomId <= 0) {
      emit(state.copyWith(
        status: BedOperationStatus.failure,
        errorMessage: () => 'Unable to load vacant beds.',
      ));
      return;
    }

    emit(state.copyWith(
      status: BedOperationStatus.loading,
      errorMessage: () => null,
    ));

    try {
      final vacantBeds = await _bedRepository.getVacantBedsByRoomId(roomId);
      emit(state.copyWith(
        status: BedOperationStatus.loaded,
        vacantBeds: vacantBeds,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: BedOperationStatus.failure,
        errorMessage: () => 'Unable to load vacant beds.',
      ));
    }
  }

  Future<void> updateBedStatus({
    required BedEntity bed,
    required BedStatus status,
  }) async {
    if (state.status == BedOperationStatus.updating) return;

    if (bed.id == null) {
      emit(state.copyWith(
        status: BedOperationStatus.failure,
        errorMessage: () => 'Invalid bed provided.',
      ));
      return;
    }

    emit(state.copyWith(
      status: BedOperationStatus.updating,
      errorMessage: () => null,
    ));

    try {
      final updatedBed = BedEntity(
        id: bed.id,
        roomId: bed.roomId,
        bedNumber: bed.bedNumber,
        status: status,
        createdAt: bed.createdAt,
        updatedAt: DateTime.now(),
      );

      await _bedRepository.updateBed(updatedBed);

      // Sync parent Room occupancy status
      await _syncRoomOccupancy(bed.roomId);

      // Reload beds to have fresh state
      final refreshedBeds = await _bedRepository.getBedsByRoomId(bed.roomId);

      emit(state.copyWith(
        status: BedOperationStatus.updated,
        beds: refreshedBeds,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: BedOperationStatus.failure,
        errorMessage: () => 'Unable to update the bed. Please try again.',
      ));
    }
  }

  Future<void> _syncRoomOccupancy(int roomId) async {
    final room = await _roomRepository.getRoomById(roomId);
    if (room == null) return;

    final beds = await _bedRepository.getBedsByRoomId(roomId);

    final newStatus =
        RoomOccupancyHelper.calculateRoomStatus(room: room, beds: beds);

    if (newStatus != room.status) {
      final updatedRoom = RoomEntity(
        id: room.id,
        hostelId: room.hostelId,
        roomNumber: room.roomNumber,
        floor: room.floor,
        roomType: room.roomType,
        numberOfBeds: room.numberOfBeds,
        monthlyRent: room.monthlyRent,
        status: newStatus,
        createdAt: room.createdAt,
        updatedAt: DateTime.now(),
      );
      await _roomRepository.updateRoom(updatedRoom);
    }
  }
}
