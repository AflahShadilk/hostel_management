import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/receipt_entity.dart';
import '../../../domain/repositories/rent_repository.dart';
import 'receipt_state.dart';

class ReceiptCubit extends Cubit<ReceiptState> {
  final RentRepository _rentRepository;

  ReceiptCubit(this._rentRepository) : super(const ReceiptInitial());

  Future<void> createReceipt(ReceiptEntity receipt) async {
    emit(const ReceiptLoading());
    try {
      await _rentRepository.createReceipt(receipt);
      await _reloadAllReceipts();
    } catch (error) {
      emit(ReceiptError(error.toString()));
    }
  }

  Future<void> loadReceiptByPaymentId(int paymentId) async {
    emit(const ReceiptLoading());
    try {
      final receipt = await _rentRepository.getReceiptByPaymentId(paymentId);
      _emitSingleReceipt(receipt);
    } catch (error) {
      emit(ReceiptError(error.toString()));
    }
  }

  Future<void> loadAllReceipts() async {
    emit(const ReceiptLoading());
    try {
      await _reloadAllReceipts();
    } catch (error) {
      emit(ReceiptError(error.toString()));
    }
  }

  Future<void> updateReceipt(ReceiptEntity receipt) async {
    emit(const ReceiptLoading());
    try {
      await _rentRepository.updateReceipt(receipt);
      await _reloadAllReceipts();
    } catch (error) {
      emit(ReceiptError(error.toString()));
    }
  }

  Future<void> deleteReceipt(int id) async {
    emit(const ReceiptLoading());
    try {
      await _rentRepository.deleteReceipt(id);
      await _reloadAllReceipts();
    } catch (error) {
      emit(ReceiptError(error.toString()));
    }
  }

  Future<void> _reloadAllReceipts() async {
    final receipts = await _rentRepository.getAllReceipts();
    if (receipts.isEmpty) {
      emit(const ReceiptEmpty());
      return;
    }
    emit(ReceiptLoaded(receipts));
  }

  void _emitSingleReceipt(ReceiptEntity? receipt) {
    if (receipt == null) {
      emit(const ReceiptEmpty());
      return;
    }
    emit(ReceiptLoaded(<ReceiptEntity>[receipt]));
  }
}
