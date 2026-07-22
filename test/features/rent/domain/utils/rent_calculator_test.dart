import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_management/features/rent/domain/utils/rent_calculator.dart';

void main() {
  group('RentCalculator', () {
    test('Case 1: Full month check-in on the 1st', () {
      final rent = RentCalculator.calculateFirstMonthRent(5000, DateTime(2023, 7, 1));
      expect(rent, 5000.0);
    });

    test('Case 2: Prorated check-in on 21st July', () {
      final rent = RentCalculator.calculateFirstMonthRent(5000, DateTime(2023, 7, 21));
      expect(rent, 1774.0);
    });

    test('Case 3: Prorated check-in on 16th Feb (28 days)', () {
      final rent = RentCalculator.calculateFirstMonthRent(6000, DateTime(2023, 2, 16));
      expect(rent, 2786.0);
    });

    test('Case 4: Prorated checkout on 20th Oct', () {
      final rent = RentCalculator.calculateCurrentMonthRent(5000, DateTime(2023, 10, 20));
      expect(rent, 3226.0);
    });

    test('Checkout on the last day of the month charges full rent', () {
      final rent = RentCalculator.calculateCurrentMonthRent(5000, DateTime(2023, 8, 31));
      expect(rent, 5000.0);
    });
  });
}
