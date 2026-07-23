import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_management/features/rent/domain/services/checkout/checkout_deposit_calculator.dart';
import 'package:hostel_management/features/rent/domain/services/checkout/checkout_rent_result.dart';

void main() {
  final rentResult = CheckoutRentResult(
    currentMonthCharge: 300,
    currentMonthPaid: 0,
    currentMonthRentStatus: 'pending',
    effectiveStartDate: DateTime(2026, 7, 1),
    totalPendingRent: 700,
    previousPendingRent: 400,
  );

  group('CheckoutDepositCalculator', () {
    test('refunds only the deposit left after finalizing every due', () {
      final result = CheckoutDepositCalculator.calculate(
        rentResult: rentResult,
        damageAmount: 100,
        otherCharges: 50,
        heldDeposit: 1000,
      );

      expect(result.totalDue, 850);
      expect(result.depositAdjustment, 850);
      expect(result.refundAmount, 150);
      expect(result.remainingAmount, 0);
      expect(result.depositStatus, 'refunded');
    });

    test('uses the full deposit only after finalizing every due', () {
      final result = CheckoutDepositCalculator.calculate(
        rentResult: rentResult,
        damageAmount: 100,
        otherCharges: 50,
        heldDeposit: 500,
      );

      expect(result.totalDue, 850);
      expect(result.depositAdjustment, 500);
      expect(result.refundAmount, 0);
      expect(result.remainingAmount, 350);
      expect(result.depositStatus, 'forfeited');
    });
  });
}
