import 'package:flutter_bloc/flutter_bloc.dart';
import 'tenant_form_state.dart';
import '../../domain/entities/tenant_status.dart';
import '../../../room/domain/entities/bed_entity.dart';

class TenantFormCubit extends Cubit<TenantFormState> {
  TenantFormCubit({
    DateTime? initialCheckIn,
    DateTime? initialCheckOut,
    TenantStatus initialStatus = TenantStatus.active,
  }) : super(TenantFormState(
          checkInDate: initialCheckIn ?? DateTime.now(),
          checkOutDate: initialCheckOut,
          status: initialStatus,
        ));

  void updateCheckInDate(DateTime date) {
    bool clearCheckOut = false;
    if (state.checkOutDate != null && state.checkOutDate!.isBefore(date)) {
      clearCheckOut = true;
    }
    emit(state.copyWith(
      checkInDate: date,
      clearCheckOutDate: clearCheckOut,
    ));
  }

  void updateCheckOutDate(DateTime? date) {
    emit(state.copyWith(
      checkOutDate: date,
      clearCheckOutDate: date == null,
    ));
  }

  void updateStatus(TenantStatus status) {
    emit(state.copyWith(status: status));
  }

  void updateSelectedBed(BedEntity? bed) {
    emit(state.copyWith(selectedBed: bed));
  }

  void enableValidation() {
    emit(state.copyWith(showValidationErrors: true));
  }
}
