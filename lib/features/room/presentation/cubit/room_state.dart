import 'package:equatable/equatable.dart';
import '../../domain/entities/room_entity.dart';
import 'room_operation_status.dart';

class RoomState extends Equatable {
  final RoomOperationStatus status;
  final List<RoomEntity> rooms;
  final RoomEntity? selectedRoom;
  final String? errorMessage;

  const RoomState({
    this.status = RoomOperationStatus.initial,
    this.rooms = const [],
    this.selectedRoom,
    this.errorMessage,
  });

  RoomState copyWith({
    RoomOperationStatus? status,
    List<RoomEntity>? rooms,
    RoomEntity? Function()? selectedRoom,
    String? Function()? errorMessage,
  }) {
    return RoomState(
      status: status ?? this.status,
      rooms: rooms ?? this.rooms,
      selectedRoom: selectedRoom != null ? selectedRoom() : this.selectedRoom,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, rooms, selectedRoom, errorMessage];
}
