import 'package:equatable/equatable.dart';

enum FinancialOnboardingStatus { ready, saving, success, failure }

class FinancialOnboardingState extends Equatable {
  const FinancialOnboardingState({
    this.status = FinancialOnboardingStatus.ready,
    this.collectDeposit = false,
    this.collectRent = false,
    this.depositPaymentMethod,
    this.rentPaymentMethod,
    this.errorMessage,
  });

  final FinancialOnboardingStatus status;
  final bool collectDeposit;
  final bool collectRent;
  final String? depositPaymentMethod;
  final String? rentPaymentMethod;
  final String? errorMessage;

  FinancialOnboardingState copyWith({
    FinancialOnboardingStatus? status,
    bool? collectDeposit,
    bool? collectRent,
    String? depositPaymentMethod,
    String? rentPaymentMethod,
    String? errorMessage,
    bool clearDepositPaymentMethod = false,
    bool clearRentPaymentMethod = false,
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
      ];
}
