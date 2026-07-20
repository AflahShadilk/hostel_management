import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/payment_entity.dart';
import '../../../domain/repositories/rent_repository.dart';
import 'payment_state.dart';

class PaymentCubit extends Cubit<PaymentState> {
  final RentRepository _rentRepository;

  PaymentCubit(this._rentRepository) : super(const PaymentInitial());

  Future<void> createPayment(PaymentEntity payment) async {
    emit(const PaymentLoading());
    try {
      final allocatedPayment = await _rentRepository.createPayment(payment);
      final paymentId = allocatedPayment.id;
      if (paymentId == null) {
        throw StateError('Allocated payment did not return an ID.');
      }
      await _rentRepository.generateReceiptForPayment(paymentId);
      await _reloadAllPayments();
    } catch (error) {
      emit(PaymentError(error.toString()));
    }
  }

  Future<void> loadPaymentById(int id) async {
    emit(const PaymentLoading());
    try {
      final payment = await _rentRepository.getPaymentById(id);
      _emitSinglePayment(payment);
    } catch (error) {
      emit(PaymentError(error.toString()));
    }
  }

  Future<void> loadPaymentsByRentRecordId(int rentRecordId) async {
    emit(const PaymentLoading());
    try {
      final payments =
          await _rentRepository.getPaymentsByRentRecordId(rentRecordId);
      _emitPayments(payments);
    } catch (error) {
      emit(PaymentError(error.toString()));
    }
  }

  Future<void> loadAllPayments() async {
    emit(const PaymentLoading());
    try {
      await _reloadAllPayments();
    } catch (error) {
      emit(PaymentError(error.toString()));
    }
  }

  Future<void> updatePayment(PaymentEntity payment) async {
    emit(const PaymentLoading());
    try {
      await _rentRepository.updatePayment(payment);
      await _reloadAllPayments();
    } catch (error) {
      emit(PaymentError(error.toString()));
    }
  }

  Future<void> deletePayment(int id) async {
    emit(const PaymentLoading());
    try {
      await _rentRepository.deletePayment(id);
      await _reloadAllPayments();
    } catch (error) {
      emit(PaymentError(error.toString()));
    }
  }

  Future<void> _reloadAllPayments() async {
    final payments = await _rentRepository.getAllPayments();
    _emitPayments(payments);
  }

  void _emitSinglePayment(PaymentEntity? payment) {
    if (payment == null) {
      emit(const PaymentEmpty());
      return;
    }
    emit(PaymentLoaded(<PaymentEntity>[payment]));
  }

  void _emitPayments(List<PaymentEntity> payments) {
    if (payments.isEmpty) {
      emit(const PaymentEmpty());
      return;
    }
    emit(PaymentLoaded(payments));
  }
}
