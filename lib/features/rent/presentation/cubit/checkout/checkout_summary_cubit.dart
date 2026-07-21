import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/rent_repository.dart';

class CheckoutSummaryState extends Equatable {
  final bool isLoading;
  final String? error;
  final double outstandingRent;
  final double depositHeld;
  final double alreadyPaid;

  const CheckoutSummaryState({
    this.isLoading = false,
    this.error,
    this.outstandingRent = 0,
    this.depositHeld = 0,
    this.alreadyPaid = 0,
  });

  CheckoutSummaryState copyWith({
    bool? isLoading,
    String? error,
    double? outstandingRent,
    double? depositHeld,
    double? alreadyPaid,
  }) {
    return CheckoutSummaryState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      outstandingRent: outstandingRent ?? this.outstandingRent,
      depositHeld: depositHeld ?? this.depositHeld,
      alreadyPaid: alreadyPaid ?? this.alreadyPaid,
    );
  }

  @override
  List<Object?> get props => [isLoading, error, outstandingRent, depositHeld, alreadyPaid];
}

class CheckoutSummaryCubit extends Cubit<CheckoutSummaryState> {
  final RentRepository _rentRepository;

  CheckoutSummaryCubit(this._rentRepository) : super(const CheckoutSummaryState());

  Future<void> loadSummary(int stayId) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final records = await _rentRepository.getRentRecordsByStayId(stayId);
      final deposit = await _rentRepository.getDepositByStayId(stayId);

      double outstandingRent = 0;
      double alreadyPaid = 0;

      for (final record in records) {
        outstandingRent += (record.amountDue - record.amountPaid);
        alreadyPaid += record.amountPaid;
      }

      double depositHeld = 0;
      if (deposit != null && deposit.status == 'held') {
        depositHeld = deposit.amount;
      }

      emit(state.copyWith(
        isLoading: false,
        outstandingRent: outstandingRent,
        depositHeld: depositHeld,
        alreadyPaid: alreadyPaid,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
