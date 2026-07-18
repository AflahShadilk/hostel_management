import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/room_type.dart';
import 'room_form_state.dart';

class RoomFormCubit extends Cubit<RoomFormState> {
  RoomFormCubit({RoomType initialType = RoomType.single})
      : super(RoomFormState(selectedRoomType: initialType));

  void selectRoomType(RoomType type) {
    emit(state.copyWith(selectedRoomType: type));
  }
}
