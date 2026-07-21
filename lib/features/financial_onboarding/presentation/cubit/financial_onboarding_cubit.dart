import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../rent/domain/constants/rent_status_constants.dart';
import '../../../rent/domain/entities/deposit_entity.dart';
import '../../../rent/domain/entities/payment_entity.dart';
import '../../../rent/domain/repositories/rent_repository.dart';
import '../../../tenant/domain/entities/tenant_registration_context.dart';
import 'financial_onboarding_state.dart';

class FinancialOnboardingCubit extends Cubit<FinancialOnboardingState> {
  FinancialOnboardingCubit(this._rentRepository)
      : super(const FinancialOnboardingState());

  final RentRepository _rentRepository;

  void setCollectDeposit(bool value) {
    emit(state.copyWith(collectDeposit: value));
  }

  void setCollectRent(bool value) {
    emit(state.copyWith(collectRent: value));
  }

  void setDepositPaymentMethod(String? value) {
    emit(state.copyWith(
      depositPaymentMethod: value,
      clearDepositPaymentMethod: value == null,
    ));
  }

  void setRentPaymentMethod(String? value) {
    emit(state.copyWith(
      rentPaymentMethod: value,
      clearRentPaymentMethod: value == null,
    ));
  }

  Future<void> save({
    required TenantRegistrationContext context,
    required double depositAmount,
    required String depositNotes,
    required double rentAmount,
    required String rentNotes,
  }) async {
    final validationMessage = _validate(
      context: context,
      depositAmount: depositAmount,
      rentAmount: rentAmount,
    );
    if (validationMessage != null) {
      emit(state.copyWith(
        status: FinancialOnboardingStatus.failure,
        errorMessage: validationMessage,
      ));
      return;
    }

    emit(state.copyWith(status: FinancialOnboardingStatus.saving));
    try {
      final now = DateTime.now();
      if (state.collectDeposit && depositAmount > 0) {
        await _rentRepository.createDeposit(
          DepositEntity(
            stayId: context.stay.id!,
            amount: depositAmount,
            refundedAmount: 0,
            receivedDate: now,
            paymentMethod: state.depositPaymentMethod!,
            notes: depositNotes.trim().isEmpty ? null : depositNotes.trim(),
            status: DepositStatus.held,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      if (state.collectRent && rentAmount > 0) {
        await _rentRepository.createPayment(
          PaymentEntity(
            rentRecordId: context.initialRentRecord.id!,
            stayId: context.stay.id!,
            tenantId: context.tenant.id!,
            amount: rentAmount,
            paymentDate: now,
            paymentMethod: state.rentPaymentMethod!,
            receiptNumber: '',
            notes: rentNotes.trim().isEmpty ? null : rentNotes.trim(),
            status: PaymentStatus.completed,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      emit(state.copyWith(status: FinancialOnboardingStatus.success));
    } catch (error) {
      emit(state.copyWith(
        status: FinancialOnboardingStatus.failure,
        errorMessage: error.toString(),
      ));
    }
  }

  String? _validate({
    required TenantRegistrationContext context,
    required double depositAmount,
    required double rentAmount,
  }) {
    if (depositAmount < 0) return 'Deposit amount cannot be negative.';
    if (rentAmount < 0) return 'Rent amount cannot be negative.';
    if (rentAmount > context.initialRentRecord.outstanding) {
      return 'Rent amount cannot exceed the outstanding amount.';
    }
    if (state.collectDeposit &&
        depositAmount > 0 &&
        state.depositPaymentMethod == null) {
      return 'Select a deposit payment method.';
    }
    if (state.collectRent && rentAmount > 0 && state.rentPaymentMethod == null) {
      return 'Select a rent payment method.';
    }
    return null;
  }
}
