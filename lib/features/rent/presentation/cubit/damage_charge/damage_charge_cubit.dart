import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/damage_charge_entity.dart';
import '../../../domain/repositories/rent_repository.dart';
import 'damage_charge_state.dart';

class DamageChargeCubit extends Cubit<DamageChargeState> {
  final RentRepository _rentRepository;

  DamageChargeCubit(this._rentRepository) : super(const DamageChargeInitial());

  Future<void> createDamageCharge(DamageChargeEntity damageCharge) async {
    emit(const DamageChargeLoading());
    try {
      await _rentRepository.createDamageCharge(damageCharge);
      await _reloadAllDamageCharges();
    } catch (error) {
      emit(DamageChargeError(error.toString()));
    }
  }

  Future<void> loadDamageChargesByStayId(int stayId) async {
    emit(const DamageChargeLoading());
    try {
      final damageCharges =
          await _rentRepository.getDamageChargesByStayId(stayId);
      _emitDamageCharges(damageCharges);
    } catch (error) {
      emit(DamageChargeError(error.toString()));
    }
  }

  Future<void> loadAllDamageCharges() async {
    emit(const DamageChargeLoading());
    try {
      await _reloadAllDamageCharges();
    } catch (error) {
      emit(DamageChargeError(error.toString()));
    }
  }

  Future<void> updateDamageCharge(DamageChargeEntity damageCharge) async {
    emit(const DamageChargeLoading());
    try {
      await _rentRepository.updateDamageCharge(damageCharge);
      await _reloadAllDamageCharges();
    } catch (error) {
      emit(DamageChargeError(error.toString()));
    }
  }

  Future<void> deleteDamageCharge(int id) async {
    emit(const DamageChargeLoading());
    try {
      await _rentRepository.deleteDamageCharge(id);
      await _reloadAllDamageCharges();
    } catch (error) {
      emit(DamageChargeError(error.toString()));
    }
  }

  Future<void> _reloadAllDamageCharges() async {
    final damageCharges = await _rentRepository.getAllDamageCharges();
    _emitDamageCharges(damageCharges);
  }

  void _emitDamageCharges(List<DamageChargeEntity> damageCharges) {
    if (damageCharges.isEmpty) {
      emit(const DamageChargeEmpty());
      return;
    }
    emit(DamageChargeLoaded(damageCharges));
  }
}
