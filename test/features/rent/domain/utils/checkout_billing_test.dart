import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_management/features/rent/domain/utils/rent_calculator.dart';

void main() {
  group('RentCalculator.calculateCurrentMonthRent — checkout billing', () {
    // ---------------------------------------------------------------
    // Mid-month checkout (20 Oct → charges 1–20 Oct)
    // Oct has 31 days. daily = 5000/31 ≈ 161.29. 20 days = 3225.80 → ₹3226
    // ---------------------------------------------------------------
    test('mid-month checkout on 20 Oct charges 1–20 Oct prorated', () {
      final checkoutDate = DateTime(2026, 10, 20);
      final result = RentCalculator.calculateCurrentMonthRent(5000, checkoutDate);
      expect(result, equals(3226.0));
    });

    // ---------------------------------------------------------------
    // Last-day checkout charges full monthly rent
    // ---------------------------------------------------------------
    test('last-day checkout (31 Oct) charges full monthly rent', () {
      final checkoutDate = DateTime(2026, 10, 31);
      final result = RentCalculator.calculateCurrentMonthRent(5000, checkoutDate);
      expect(result, equals(5000.0));
    });

    test('last-day checkout in February (non-leap) charges full monthly rent', () {
      final checkoutDate = DateTime(2026, 2, 28);
      final result = RentCalculator.calculateCurrentMonthRent(5000, checkoutDate);
      expect(result, equals(5000.0));
    });

    test('last-day checkout in February (leap year) charges full monthly rent', () {
      final checkoutDate = DateTime(2024, 2, 29);
      final result = RentCalculator.calculateCurrentMonthRent(5000, checkoutDate);
      expect(result, equals(5000.0));
    });

    // ---------------------------------------------------------------
    // 1st-day checkout charges only 1 day
    // Oct: 5000/31 ≈ 161.29 → ₹161
    // ---------------------------------------------------------------
    test('checkout on 1st of month charges only 1 day', () {
      final checkoutDate = DateTime(2026, 10, 1);
      final result = RentCalculator.calculateCurrentMonthRent(5000, checkoutDate);
      expect(result, equals(161.0));
    });

    // ---------------------------------------------------------------
    // February mid-month (14 Feb, 28-day year)
    // daily = 5000/28 ≈ 178.57. 14 days = 2500 → ₹2500
    // ---------------------------------------------------------------
    test('mid-month checkout on 14 Feb (non-leap) charges correctly', () {
      final checkoutDate = DateTime(2026, 2, 14);
      final result = RentCalculator.calculateCurrentMonthRent(5000, checkoutDate);
      expect(result, equals(2500.0));
    });

    // ---------------------------------------------------------------
    // June (30 days), checkout on 15th
    // daily = 5000/30 ≈ 166.67. 15 days = 2500 → ₹2500
    // ---------------------------------------------------------------
    test('mid-month checkout on 15 Jun charges half month', () {
      final checkoutDate = DateTime(2026, 6, 15);
      final result = RentCalculator.calculateCurrentMonthRent(5000, checkoutDate);
      expect(result, equals(2500.0));
    });

    // ---------------------------------------------------------------
    // Rounding — amounts should be rounded to nearest rupee
    // ---------------------------------------------------------------
    test('result is always rounded to nearest rupee (no decimals)', () {
      final checkoutDate = DateTime(2026, 10, 20);
      final result = RentCalculator.calculateCurrentMonthRent(5000, checkoutDate);
      expect(result, equals(result.roundToDouble()));
    });
  });

  group('Settlement final amounts', () {
    // ---------------------------------------------------------------
    // No pending rent, deposit covers everything → refund
    // ---------------------------------------------------------------
    test('deposit covers total due → positive refund to tenant', () {
      const monthlyRent = 5000.0;
      final checkoutDate = DateTime(2026, 10, 20);
      final currentMonthCharge = RentCalculator.calculateCurrentMonthRent(
        monthlyRent,
        checkoutDate,
      );
      const pendingRent = 0.0;
      const damageCharges = 0.0;
      const depositHeld = 10000.0;

      final totalDue = pendingRent + currentMonthCharge + damageCharges;
      final netAfterDeposit = depositHeld - totalDue;

      expect(totalDue, equals(3226.0));
      expect(netAfterDeposit, greaterThan(0)); // hostel owes tenant
      expect(netAfterDeposit, equals(10000.0 - 3226.0));
    });

    // ---------------------------------------------------------------
    // Pending rent exists — adds to total due
    // ---------------------------------------------------------------
    test('pending rent from previous months adds to total due', () {
      const monthlyRent = 5000.0;
      final checkoutDate = DateTime(2026, 10, 20);
      final currentMonthCharge = RentCalculator.calculateCurrentMonthRent(
        monthlyRent,
        checkoutDate,
      );
      const pendingRent = 5000.0; // one unpaid full month
      const damageCharges = 500.0;
      const depositHeld = 5000.0;

      final totalDue = pendingRent + currentMonthCharge + damageCharges;
      final netAfterDeposit = depositHeld - totalDue;

      expect(totalDue, equals(5000.0 + 3226.0 + 500.0));
      expect(netAfterDeposit, lessThan(0)); // tenant owes hostel
    });

    // ---------------------------------------------------------------
    // Deposit exactly covers total → zero refund, zero balance
    // ---------------------------------------------------------------
    test('deposit exactly matches total due → zero both sides', () {
      const monthlyRent = 5000.0;
      final checkoutDate = DateTime(2026, 6, 15); // 15 Jun → ₹2500
      final currentMonthCharge = RentCalculator.calculateCurrentMonthRent(
        monthlyRent,
        checkoutDate,
      );
      const pendingRent = 0.0;
      const depositHeld = 2500.0;
      const damageCharges = 0.0;

      final totalDue = pendingRent + currentMonthCharge + damageCharges;
      final refund = (depositHeld - totalDue).clamp(0, double.infinity).toDouble();
      final remaining = (totalDue - depositHeld).clamp(0, double.infinity).toDouble();

      expect(refund, equals(0.0));
      expect(remaining, equals(0.0));
    });

    // ---------------------------------------------------------------
    // No deposit held — tenant owes full balance
    // ---------------------------------------------------------------
    test('no deposit held — tenant owes full total due', () {
      const monthlyRent = 5000.0;
      final checkoutDate = DateTime(2026, 10, 31); // full month
      final currentMonthCharge = RentCalculator.calculateCurrentMonthRent(
        monthlyRent,
        checkoutDate,
      );
      const pendingRent = 0.0;
      const depositHeld = 0.0;
      const damageCharges = 0.0;

      final totalDue = pendingRent + currentMonthCharge + damageCharges;
      final remaining = (totalDue - depositHeld).clamp(0, double.infinity).toDouble();

      expect(currentMonthCharge, equals(5000.0)); // last day → full rent
      expect(remaining, equals(5000.0));
    });
  });
}
