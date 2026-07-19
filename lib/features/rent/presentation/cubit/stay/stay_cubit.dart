import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/stay_entity.dart';
import '../../../domain/repositories/rent_repository.dart';
import 'stay_state.dart';

class StayCubit extends Cubit<StayState> {
  final RentRepository _rentRepository;

  StayCubit(this._rentRepository) : super(const StayInitial());

  Future<void> createStay(StayEntity stay) async {
    emit(const StayLoading());
    try {
      await _rentRepository.checkInTenant(
        tenantId: stay.tenantId,
        roomId: stay.roomId,
        bedId: stay.bedId,
        checkInDate: stay.checkInDate,
        expectedCheckoutDate: stay.expectedCheckoutDate,
        monthlyRent: stay.monthlyRentSnapshot,
        dailyRate: stay.dailyRate,
        depositAmount: 0.0, // UI does not currently collect this
      );
      await _reloadAllStays();
    } catch (error) {
      emit(StayError(error.toString()));
    }
  }

  Future<void> loadStayById(int id) async {
    emit(const StayLoading());
    try {
      final stay = await _rentRepository.getStayById(id);
      _emitSingleStay(stay);
    } catch (error) {
      emit(StayError(error.toString()));
    }
  }

  Future<void> loadActiveStayByTenantId(int tenantId) async {
    emit(const StayLoading());
    try {
      final stay = await _rentRepository.getActiveStayByTenantId(tenantId);
      _emitSingleStay(stay);
    } catch (error) {
      emit(StayError(error.toString()));
    }
  }

  Future<void> loadAllStays() async {
    emit(const StayLoading());
    try {
      await _reloadAllStays();
    } catch (error) {
      emit(StayError(error.toString()));
    }
  }

  Future<void> updateStay(StayEntity stay) async {
    emit(const StayLoading());
    try {
      await _rentRepository.updateStay(stay);
      await _reloadAllStays();
    } catch (error) {
      emit(StayError(error.toString()));
    }
  }

  Future<void> deleteStay(int id) async {
    emit(const StayLoading());
    try {
      await _rentRepository.deleteStay(id);
      await _reloadAllStays();
    } catch (error) {
      emit(StayError(error.toString()));
    }
  }

  Future<void> _reloadAllStays() async {
    final stays = await _rentRepository.getAllStays();
    if (stays.isEmpty) {
      emit(const StayEmpty());
      return;
    }
    emit(StayLoaded(stays));
  }

  void _emitSingleStay(StayEntity? stay) {
    if (stay == null) {
      emit(const StayEmpty());
      return;
    }
    emit(StayLoaded(<StayEntity>[stay]));
  }
}
