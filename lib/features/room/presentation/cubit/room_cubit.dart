import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/room_entity.dart';
import '../../domain/entities/room_status.dart';
import '../../domain/entities/room_type.dart';
import '../../domain/repositories/room_repository.dart';
import '../../domain/repositories/room_management_repository.dart';
import 'room_state.dart';
import 'room_operation_status.dart';

class RoomCubit extends Cubit<RoomState> {
  final RoomRepository _roomRepository;
  final RoomManagementRepository _roomManagementRepository;

  RoomCubit(
    this._roomRepository,
    this._roomManagementRepository,
  ) : super(const RoomState());

  Future<void> loadRooms(int hostelId) async {
    if (hostelId <= 0) {
      emit(state.copyWith(
        status: RoomOperationStatus.failure,
        errorMessage: () => 'Unable to load rooms.',
      ));
      return;
    }

    emit(state.copyWith(
      status: RoomOperationStatus.loading,
      errorMessage: () => null,
    ));

    try {
      final rooms = await _roomRepository.getRoomsByHostelId(hostelId);
      emit(state.copyWith(
        status: RoomOperationStatus.loaded,
        rooms: rooms,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: RoomOperationStatus.failure,
        errorMessage: () => 'Unable to load rooms.',
      ));
    }
  }

  Future<void> createRoom({
    required int hostelId,
    required String roomNumber,
    required String floor,
    required RoomType roomType,
    required int numberOfBeds,
    required double monthlyRent,
  }) async {
    if (_isMutating()) return;

    if (hostelId <= 0 ||
        roomNumber.trim().isEmpty ||
        floor.trim().isEmpty ||
        numberOfBeds <= 0 ||
        monthlyRent < 0) {
      emit(state.copyWith(
        status: RoomOperationStatus.failure,
        errorMessage: () => 'Invalid room data provided.',
      ));
      return;
    }

    emit(state.copyWith(
      status: RoomOperationStatus.creating,
      errorMessage: () => null,
    ));

    try {
      final exists = await _roomRepository.roomNumberExists(
        hostelId: hostelId,
        roomNumber: roomNumber,
      );

      if (exists) {
        emit(state.copyWith(
          status: RoomOperationStatus.failure,
          errorMessage: () => 'A room with this number already exists.',
        ));
        return;
      }

      final now = DateTime.now();
      final newRoom = RoomEntity(
        id: null,
        hostelId: hostelId,
        roomNumber: roomNumber.trim(),
        floor: floor.trim(),
        roomType: roomType,
        numberOfBeds: numberOfBeds,
        monthlyRent: monthlyRent,
        status: RoomStatus.vacant,
        createdAt: now,
        updatedAt: now,
      );

      final createdRoom =
          await _roomManagementRepository.createRoomWithBeds(room: newRoom);

      // Refresh list locally
      final updatedRooms = List<RoomEntity>.from(state.rooms)..add(createdRoom);

      emit(state.copyWith(
        status: RoomOperationStatus.created,
        rooms: updatedRooms,
        selectedRoom: () => createdRoom,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: RoomOperationStatus.failure,
        errorMessage: () => 'Unable to create the room. Please try again.',
      ));
    }
  }

  Future<void> updateRoom({
    required RoomEntity currentRoom,
    required String roomNumber,
    required String floor,
    required RoomType roomType,
    required int numberOfBeds,
    required double monthlyRent,
  }) async {
    if (_isMutating()) return;

    if (currentRoom.id == null ||
        roomNumber.trim().isEmpty ||
        floor.trim().isEmpty ||
        numberOfBeds <= 0 ||
        monthlyRent < 0) {
      emit(state.copyWith(
        status: RoomOperationStatus.failure,
        errorMessage: () => 'Invalid room data provided.',
      ));
      return;
    }

    emit(state.copyWith(
      status: RoomOperationStatus.updating,
      errorMessage: () => null,
    ));

    try {
      final exists = await _roomRepository.roomNumberExists(
        hostelId: currentRoom.hostelId,
        roomNumber: roomNumber,
        excludeRoomId: currentRoom.id,
      );

      if (exists) {
        emit(state.copyWith(
          status: RoomOperationStatus.failure,
          errorMessage: () => 'A room with this number already exists.',
        ));
        return;
      }

      final updatedRoom = RoomEntity(
        id: currentRoom.id,
        hostelId: currentRoom.hostelId,
        roomNumber: roomNumber.trim(),
        floor: floor.trim(),
        roomType: roomType,
        numberOfBeds: numberOfBeds,
        monthlyRent: monthlyRent,
        status:
            currentRoom.status, // normal update doesn't touch status directly
        createdAt: currentRoom.createdAt,
        updatedAt: DateTime.now(),
      );

      RoomEntity finalRoom;

      if (currentRoom.numberOfBeds != numberOfBeds) {
        // Capacity changed, use structural repo
        finalRoom = await _roomManagementRepository.updateRoomWithCapacity(
          currentRoom: currentRoom,
          updatedRoom: updatedRoom,
        );
      } else {
        // Only normal fields changed, use normal repo
        await _roomRepository.updateRoom(updatedRoom);
        finalRoom = updatedRoom;
      }

      final updatedRooms =
          state.rooms.map((r) => r.id == finalRoom.id ? finalRoom : r).toList();

      emit(state.copyWith(
        status: RoomOperationStatus.updated,
        rooms: updatedRooms,
        selectedRoom: () => finalRoom,
      ));
    } on StateError catch (e) {
      emit(state.copyWith(
        status: RoomOperationStatus.failure,
        errorMessage: () => e.message,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: RoomOperationStatus.failure,
        errorMessage: () => 'Unable to update the room. Please try again.',
      ));
    }
  }

  Future<void> deleteRoom(RoomEntity room) async {
    if (_isMutating()) return;

    if (room.id == null) {
      emit(state.copyWith(
        status: RoomOperationStatus.failure,
        errorMessage: () => 'Invalid room provided.',
      ));
      return;
    }

    emit(state.copyWith(
      status: RoomOperationStatus.deleting,
      errorMessage: () => null,
    ));

    try {
      await _roomRepository.deleteRoom(room.id!);

      final updatedRooms = state.rooms.where((r) => r.id != room.id).toList();

      emit(state.copyWith(
        status: RoomOperationStatus.deleted,
        rooms: updatedRooms,
        selectedRoom: () => null,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: RoomOperationStatus.failure,
        errorMessage: () => 'Unable to delete the room. Please try again.',
      ));
    }
  }

  bool _isMutating() {
    return state.status == RoomOperationStatus.creating ||
        state.status == RoomOperationStatus.updating ||
        state.status == RoomOperationStatus.deleting;
  }
}
