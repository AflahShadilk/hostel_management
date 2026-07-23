import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/rent_repository.dart';
import '../../../domain/utils/rent_calculator.dart';

class CheckoutSummaryState extends Equatable {
  final bool isLoading;
  final String? error;
  final double monthlyRent;
  final double currentMonthCharge;
  final double currentMonthChargeStartDay;
  final double currentMonthChargeEndDay;
  final double pendingRent;
  final double depositHeld;
  final double alreadyPaid;
  final double currentMonthPaid;

  const CheckoutSummaryState({
    this.isLoading = false,
    this.error,
    this.monthlyRent = 0,
    this.currentMonthCharge = 0,
    this.currentMonthChargeStartDay = 1,
    this.currentMonthChargeEndDay = 0,
    this.pendingRent = 0,
    this.depositHeld = 0,
    this.alreadyPaid = 0,
    this.currentMonthPaid = 0,
  });

  /// Kept for backward compatibility with any code that reads outstandingRent.
  double get outstandingRent => pendingRent + currentMonthCharge - currentMonthPaid;

  CheckoutSummaryState copyWith({
    bool? isLoading,
    String? error,
    double? monthlyRent,
    double? currentMonthCharge,
    double? currentMonthChargeStartDay,
    double? currentMonthChargeEndDay,
    double? pendingRent,
    double? depositHeld,
    double? alreadyPaid,
    double? currentMonthPaid,
  }) {
    return CheckoutSummaryState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      currentMonthCharge: currentMonthCharge ?? this.currentMonthCharge,
      currentMonthChargeStartDay:
          currentMonthChargeStartDay ?? this.currentMonthChargeStartDay,
      currentMonthChargeEndDay:
          currentMonthChargeEndDay ?? this.currentMonthChargeEndDay,
      pendingRent: pendingRent ?? this.pendingRent,
      depositHeld: depositHeld ?? this.depositHeld,
      alreadyPaid: alreadyPaid ?? this.alreadyPaid,
      currentMonthPaid: currentMonthPaid ?? this.currentMonthPaid,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        error,
        monthlyRent,
        currentMonthCharge,
        currentMonthChargeStartDay,
        currentMonthChargeEndDay,
        pendingRent,
        depositHeld,
        alreadyPaid,
      ];
}

class CheckoutSummaryCubit extends Cubit<CheckoutSummaryState> {
  final RentRepository _rentRepository;

  CheckoutSummaryCubit(this._rentRepository)
      : super(const CheckoutSummaryState());

  Future<void> loadSummary(int stayId, {DateTime? checkoutDate}) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final stay = await _rentRepository.getStayById(stayId);
      if (stay == null) throw Exception('Stay not found.');
      final records =
          await _rentRepository.getRentRecordsByTenantId(stay.tenantId);
      final deposit = await _rentRepository.getDepositByStayId(stayId);

      double pendingRent = 0;
      double alreadyPaid = 0;
      double currentMonthPaid = 0;
      final effectiveCheckoutDate = checkoutDate ?? DateTime.now();
      final currentMonthPrefix =
          '${effectiveCheckoutDate.year}-${effectiveCheckoutDate.month.toString().padLeft(2, '0')}';

      final checkInMonth = DateTime(stay.checkInDate.year, stay.checkInDate.month, 1);

      for (final record in records) {
        if (record.startDate.toIso8601String().startsWith(currentMonthPrefix)) {
          // This is the current month's rent record.
          alreadyPaid += record.amountPaid;
          currentMonthPaid += record.amountPaid;
        } else {
          if (!record.startDate.isBefore(checkInMonth)) {
            pendingRent += record.outstanding.clamp(0, double.infinity);
          }
          alreadyPaid += record.amountPaid;
        }
      }

      // Current month prorated charge — computed here for display only.
      // The actual calculation is re-performed by the repository on commit.
      final monthlyRent = stay.monthlyRentSnapshot;
      final currentMonthCharge = monthlyRent > 0
          ? RentCalculator.calculateCurrentMonthRent(
              monthlyRent,
              effectiveCheckoutDate,
              checkInDate: stay.checkInDate,
            )
          : 0.0;

      double depositHeld = 0;
      if (deposit != null && deposit.status == 'held') {
        depositHeld = deposit.amount;
      }

      final firstDayOfCurrentMonth = DateTime(
          effectiveCheckoutDate.year, effectiveCheckoutDate.month, 1);
      final cleanCheckIn = DateTime(
          stay.checkInDate.year, stay.checkInDate.month, stay.checkInDate.day);
      final effectiveStartDate = cleanCheckIn.isAfter(firstDayOfCurrentMonth)
          ? cleanCheckIn
          : firstDayOfCurrentMonth;

      emit(state.copyWith(
        isLoading: false,
        monthlyRent: monthlyRent,
        currentMonthCharge: currentMonthCharge,
        currentMonthChargeStartDay: effectiveStartDate.day.toDouble(),
        currentMonthChargeEndDay: effectiveCheckoutDate.day.toDouble(),
        pendingRent: pendingRent,
        depositHeld: depositHeld,
        alreadyPaid: alreadyPaid,
        currentMonthPaid: currentMonthPaid,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
