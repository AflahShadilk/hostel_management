import 'package:equatable/equatable.dart';
import '../../../room/domain/entities/room_entity.dart';
import '../../../room/domain/entities/bed_entity.dart';

class RoomWithBeds extends Equatable {
  final RoomEntity room;
  final List<BedEntity> beds;
  
  const RoomWithBeds(this.room, this.beds);

  @override
  List<Object?> get props => [room, beds];
}

abstract class BedSelectionState extends Equatable {
  const BedSelectionState();
  
  @override
  List<Object?> get props => [];
}

class BedSelectionInitial extends BedSelectionState {}

class BedSelectionLoading extends BedSelectionState {}

class BedSelectionLoaded extends BedSelectionState {
  final List<RoomWithBeds> roomWithBeds;
  const BedSelectionLoaded(this.roomWithBeds);

  @override
  List<Object?> get props => [roomWithBeds];
}

class BedSelectionError extends BedSelectionState {
  final String message;
  const BedSelectionError(this.message);

  @override
  List<Object?> get props => [message];
}
