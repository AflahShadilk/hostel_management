import 'package:equatable/equatable.dart';
import '../../domain/entities/room_type.dart';

class RoomFormState extends Equatable {
  final RoomType selectedRoomType;

  const RoomFormState({
    this.selectedRoomType = RoomType.single,
  });

  RoomFormState copyWith({RoomType? selectedRoomType}) {
    return RoomFormState(
      selectedRoomType: selectedRoomType ?? this.selectedRoomType,
    );
  }

  @override
  List<Object?> get props => [selectedRoomType];
}
