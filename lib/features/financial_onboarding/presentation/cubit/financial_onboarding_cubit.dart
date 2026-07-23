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

  void init(TenantRegistrationContext context) {
    // The outstanding on the initial rent record is correctly prorated by RentCalculator
    final rent = context.initialRentRecord.outstanding;
    emit(state.copyWith(
      firstMonthRent: rent,
      outstandingAmount: rent,
    ));
  }

  void rentReceivedChanged(String value) {
    final amount = double.tryParse(value.trim()) ?? 0.0;
    var outstanding = state.firstMonthRent - amount;
    if (outstanding < 0) {
      outstanding = 0.0;
    }
    emit(state.copyWith(outstandingAmount: outstanding));
  }

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

  /// Saves a single financial section (deposit-only or rent-only).
  ///
  /// This method NEVER completes onboarding. It only persists the data for the
  /// requested section and emits [FinancialOnboardingStatus.stepSaved] to signal
  /// the UI to update (e.g. show a confirmation indicator) while staying on page.
  ///
  /// Call [finish] to finalise onboarding after both sections are resolved.
  Future<void> saveSection({
    required TenantRegistrationContext context,
    required double depositAmount,
    required String depositNotes,
    required double rentAmount,
    required String rentNotes,
    bool processDeposit = false,
    bool processRent = false,
  }) async {
    assert(
      processDeposit != processRent,
      'saveSection must target exactly one section at a time.',
    );

    final validationMessage = _validate(
      context: context,
      depositAmount: depositAmount,
      rentAmount: rentAmount,
      processDeposit: processDeposit,
      processRent: processRent,
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

      if (processDeposit && depositAmount > 0) {
        await _rentRepository.createDeposit(
          DepositEntity(
            stayId: context.stay.id!,
            amount: depositAmount,
            refundedAmount: 0,
            receivedDate: now,
            paymentMethod: state.depositPaymentMethod ?? PaymentMethod.cash,
            notes: depositNotes.trim().isEmpty ? null : depositNotes.trim(),
            status: DepositStatus.held,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      if (processRent && rentAmount > 0) {
        await _rentRepository.createPayment(
          PaymentEntity(
            rentRecordId: context.initialRentRecord.id!,
            stayId: context.stay.id!,
            tenantId: context.tenant.id!,
            amount: rentAmount,
            paymentDate: now,
            paymentMethod: state.rentPaymentMethod ?? PaymentMethod.cash,
            receiptNumber: '',
            notes: rentNotes.trim().isEmpty ? null : rentNotes.trim(),
            status: PaymentStatus.completed,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      // Mark only the section that was just processed as done.
      // The page stays open — the other section is still pending.
      emit(state.copyWith(
        status: FinancialOnboardingStatus.stepSaved,
        depositDone: processDeposit ? true : null,
        rentDone: processRent ? true : null,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: FinancialOnboardingStatus.failure,
        errorMessage: error.toString(),
      ));
    }
  }

  /// Saves any remaining unsaved sections and finalises onboarding.
  ///
  /// This is the ONLY method allowed to emit [FinancialOnboardingStatus.completed],
  /// which is the signal for the page to navigate away.
  ///
  /// Any section that has not yet been individually saved will be processed here
  /// using the current field values. Sections already marked done via [saveSection]
  /// are skipped (their data has already been persisted).
  Future<void> finish({
    required TenantRegistrationContext context,
    required double depositAmount,
    required String depositNotes,
    required double rentAmount,
    required String rentNotes,
  }) async {
    // Only validate sections that have not yet been saved.
    final needsDeposit = !state.depositDone;
    final needsRent = !state.rentDone;

    if (needsDeposit || needsRent) {
      final validationMessage = _validate(
        context: context,
        depositAmount: depositAmount,
        rentAmount: rentAmount,
        processDeposit: needsDeposit,
        processRent: needsRent,
      );
      if (validationMessage != null) {
        emit(state.copyWith(
          status: FinancialOnboardingStatus.failure,
          errorMessage: validationMessage,
        ));
        return;
      }
    }

    emit(state.copyWith(status: FinancialOnboardingStatus.saving));
    try {
      final now = DateTime.now();

      if (needsDeposit && depositAmount > 0) {
        await _rentRepository.createDeposit(
          DepositEntity(
            stayId: context.stay.id!,
            amount: depositAmount,
            refundedAmount: 0,
            receivedDate: now,
            paymentMethod: state.depositPaymentMethod ?? PaymentMethod.cash,
            notes: depositNotes.trim().isEmpty ? null : depositNotes.trim(),
            status: DepositStatus.held,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      if (needsRent && rentAmount > 0) {
        await _rentRepository.createPayment(
          PaymentEntity(
            rentRecordId: context.initialRentRecord.id!,
            stayId: context.stay.id!,
            tenantId: context.tenant.id!,
            amount: rentAmount,
            paymentDate: now,
            paymentMethod: state.rentPaymentMethod ?? PaymentMethod.cash,
            receiptNumber: '',
            notes: rentNotes.trim().isEmpty ? null : rentNotes.trim(),
            status: PaymentStatus.completed,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      // Both sections are now resolved. Signal the page to navigate away.
      emit(state.copyWith(
        status: FinancialOnboardingStatus.completed,
        depositDone: true,
        rentDone: true,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: FinancialOnboardingStatus.failure,
        errorMessage: error.toString(),
      ));
    }
  }

  /// Explicitly skips any unfinished sections and finalises onboarding.
  /// No database records are created for the skipped sections.
  void skipAndFinish() {
    emit(state.copyWith(
      status: FinancialOnboardingStatus.completed,
      depositDone: true,
      rentDone: true,
    ));
  }

  String? _validate({
    required TenantRegistrationContext context,
    required double depositAmount,
    required double rentAmount,
    required bool processDeposit,
    required bool processRent,
  }) {
    if (processDeposit) {
      if (depositAmount < 0) return 'Deposit amount cannot be negative.';
      if (depositAmount > 0 && state.depositPaymentMethod == null) {
        return 'Select a deposit payment method.';
      }
    }

    if (processRent) {
      if (rentAmount < 0) return 'Rent amount cannot be negative.';
      if (rentAmount > state.firstMonthRent) {
        return 'Rent amount cannot exceed the outstanding amount.';
      }
      if (rentAmount > 0 && state.rentPaymentMethod == null) {
        return 'Select a rent payment method.';
      }
    }
    return null;
  }
}
