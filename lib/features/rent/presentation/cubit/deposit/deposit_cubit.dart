import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/deposit_entity.dart';
import '../../../domain/repositories/rent_repository.dart';
import 'deposit_state.dart';

class DepositCubit extends Cubit<DepositState> {
  final RentRepository _rentRepository;

  DepositCubit(this._rentRepository) : super(const DepositInitial());

  Future<void> createDeposit(DepositEntity deposit) async {
    emit(const DepositLoading());
    try {
      await _rentRepository.createDeposit(deposit);
      await _reloadAllDeposits();
    } catch (error) {
      emit(DepositError(error.toString()));
    }
  }

  Future<void> loadDepositByStayId(int stayId) async {
    emit(const DepositLoading());
    try {
      final deposit = await _rentRepository.getDepositByStayId(stayId);
      _emitSingleDeposit(deposit);
    } catch (error) {
      emit(DepositError(error.toString()));
    }
  }

  Future<void> loadAllDeposits() async {
    emit(const DepositLoading());
    try {
      await _reloadAllDeposits();
    } catch (error) {
      emit(DepositError(error.toString()));
    }
  }

  Future<void> updateDeposit(DepositEntity deposit) async {
    emit(const DepositLoading());
    try {
      await _rentRepository.updateDeposit(deposit);
      await _reloadAllDeposits();
    } catch (error) {
      emit(DepositError(error.toString()));
    }
  }

  Future<void> deleteDeposit(int id) async {
    emit(const DepositLoading());
    try {
      await _rentRepository.deleteDeposit(id);
      await _reloadAllDeposits();
    } catch (error) {
      emit(DepositError(error.toString()));
    }
  }

  Future<void> _reloadAllDeposits() async {
    final deposits = await _rentRepository.getAllDeposits();
    if (deposits.isEmpty) {
      emit(const DepositEmpty());
      return;
    }
    emit(DepositLoaded(deposits));
  }

  void _emitSingleDeposit(DepositEntity? deposit) {
    if (deposit == null) {
      emit(const DepositEmpty());
      return;
    }
    emit(DepositLoaded(<DepositEntity>[deposit]));
  }
}
