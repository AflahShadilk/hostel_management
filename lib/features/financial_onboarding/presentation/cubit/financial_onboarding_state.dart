import 'package:equatable/equatable.dart';

enum FinancialOnboardingStatus {
  /// Idle — ready to accept user input.
  ready,

  /// A save operation is currently in progress.
  saving,

  /// A single section (deposit OR rent) was saved successfully.
  /// The page must NOT navigate away — the other section may still be pending.
  stepSaved,

  /// Both sections have been resolved (collected or skipped).
  /// This is the ONLY status that should trigger navigation away from the page.
  completed,

  /// A save or validation operation failed.
  failure,
}

class FinancialOnboardingState extends Equatable {
  const FinancialOnboardingState({
    this.status = FinancialOnboardingStatus.ready,
    this.collectDeposit = false,
    this.collectRent = false,
    this.depositPaymentMethod,
    this.rentPaymentMethod,
    this.errorMessage,
    this.firstMonthRent = 0.0,
    this.outstandingAmount = 0.0,
    this.depositDone = false,
    this.rentDone = false,
  });

  final FinancialOnboardingStatus status;
  final bool collectDeposit;
  final bool collectRent;
  final String? depositPaymentMethod;
  final String? rentPaymentMethod;
  final String? errorMessage;
  final double firstMonthRent;
  final double outstandingAmount;

  /// True once the Security Deposit section has been collected or explicitly skipped.
  final bool depositDone;

  /// True once the First Rent section has been collected or explicitly skipped.
  final bool rentDone;

  /// Both sections have been resolved — onboarding is allowed to complete.
  bool get bothSectionsResolved => depositDone && rentDone;

  FinancialOnboardingState copyWith({
    FinancialOnboardingStatus? status,
    bool? collectDeposit,
    bool? collectRent,
    String? depositPaymentMethod,
    String? rentPaymentMethod,
    String? errorMessage,
    bool clearDepositPaymentMethod = false,
    bool clearRentPaymentMethod = false,
    double? firstMonthRent,
    double? outstandingAmount,
    bool? depositDone,
    bool? rentDone,
  }) {
    return FinancialOnboardingState(
      status: status ?? this.status,
      collectDeposit: collectDeposit ?? this.collectDeposit,
      collectRent: collectRent ?? this.collectRent,
      depositPaymentMethod: clearDepositPaymentMethod
          ? null
          : depositPaymentMethod ?? this.depositPaymentMethod,
      rentPaymentMethod: clearRentPaymentMethod
          ? null
          : rentPaymentMethod ?? this.rentPaymentMethod,
      errorMessage: errorMessage,
      firstMonthRent: firstMonthRent ?? this.firstMonthRent,
      outstandingAmount: outstandingAmount ?? this.outstandingAmount,
      depositDone: depositDone ?? this.depositDone,
      rentDone: rentDone ?? this.rentDone,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        collectDeposit,
        collectRent,
        depositPaymentMethod,
        rentPaymentMethod,
        errorMessage,
        firstMonthRent,
        outstandingAmount,
        depositDone,
        rentDone,
      ];
}
