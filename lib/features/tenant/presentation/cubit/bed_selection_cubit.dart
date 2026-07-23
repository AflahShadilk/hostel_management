import 'package:flutter_bloc/flutter_bloc.dart';
import 'bed_selection_state.dart';
import '../../../room/domain/entities/bed_status.dart';
import '../../../room/domain/repositories/room_repository.dart';
import '../../../room/domain/repositories/bed_repository.dart';

class BedSelectionCubit extends Cubit<BedSelectionState> {
  final RoomRepository _roomRepository;
  final BedRepository _bedRepository;

  BedSelectionCubit(this._roomRepository, this._bedRepository)
      : super(BedSelectionInitial());

  Future<void> loadAvailableBeds(int hostelId) async {
    emit(BedSelectionLoading());
    try {
      final rooms = await _roomRepository.getRoomsByHostelId(hostelId);
      final result = <RoomWithBeds>[];

      for (final room in rooms) {
        if (room.id == null) continue;
        final beds = await _bedRepository.getVacantBedsByRoomId(room.id!);
        final activeBeds =
            beds.where((b) => b.status == BedStatus.vacant).toList();
        if (activeBeds.isNotEmpty) {
          result.add(RoomWithBeds(room, activeBeds));
        }
      }
      emit(BedSelectionLoaded(result));
    } catch (e) {
      emit(BedSelectionError(e.toString()));
    }
  }
}
