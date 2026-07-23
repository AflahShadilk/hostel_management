import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/checkout_settlement_entity.dart';
import '../../../domain/entities/checkout_request.dart';
import '../../../domain/repositories/rent_repository.dart';
import 'checkout_state.dart';

class CheckoutCubit extends Cubit<CheckoutState> {
  final RentRepository _rentRepository;

  CheckoutCubit(this._rentRepository) : super(const CheckoutInitial());

  Future<void> createCheckoutSettlement(
    CheckoutSettlementEntity settlement,
  ) async {
    emit(const CheckoutLoading());
    try {
      await _rentRepository.createCheckoutSettlement(settlement);
      await _reloadAllCheckoutSettlements();
    } catch (error) {
      emit(CheckoutError(error.toString()));
    }
  }

  Future<void> loadCheckoutSettlementByStayId(int stayId) async {
    emit(const CheckoutLoading());
    try {
      final settlement =
          await _rentRepository.getCheckoutSettlementByStayId(stayId);
      _emitSingleSettlement(settlement);
    } catch (error) {
      emit(CheckoutError(error.toString()));
    }
  }

  Future<void> loadAllCheckoutSettlements() async {
    emit(const CheckoutLoading());
    try {
      await _reloadAllCheckoutSettlements();
    } catch (error) {
      emit(CheckoutError(error.toString()));
    }
  }

  Future<void> updateCheckoutSettlement(
    CheckoutSettlementEntity settlement,
  ) async {
    emit(const CheckoutLoading());
    try {
      await _rentRepository.updateCheckoutSettlement(settlement);
      await _reloadAllCheckoutSettlements();
    } catch (error) {
      emit(CheckoutError(error.toString()));
    }
  }

  Future<void> deleteCheckoutSettlement(int id) async {
    emit(const CheckoutLoading());
    try {
      await _rentRepository.deleteCheckoutSettlement(id);
      await _reloadAllCheckoutSettlements();
    } catch (error) {
      emit(CheckoutError(error.toString()));
    }
  }

  Future<void> completeCheckout(CheckoutRequest request) async {
    emit(const CheckoutLoading());
    try {
      await _rentRepository.completeCheckout(request);
      await _reloadAllCheckoutSettlements();
    } catch (error) {
      emit(CheckoutError(error.toString()));
    }
  }

  Future<void> _reloadAllCheckoutSettlements() async {
    final settlements = await _rentRepository.getAllCheckoutSettlements();
    if (settlements.isEmpty) {
      emit(const CheckoutEmpty());
      return;
    }
    emit(CheckoutLoaded(settlements));
  }

  void _emitSingleSettlement(CheckoutSettlementEntity? settlement) {
    if (settlement == null) {
      emit(const CheckoutEmpty());
      return;
    }
    emit(CheckoutLoaded(<CheckoutSettlementEntity>[settlement]));
  }
}
