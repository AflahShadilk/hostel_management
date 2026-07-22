// lib/features/rent/domain/utils/rent_calculator.dart

class RentCalculator {
  /// Calculates the prorated rent for the first month based on the check-in date.
  /// The FIRST month is always prorated.
  static double calculateFirstMonthRent(double monthlyRent, DateTime checkInDate) {
    // If checking in on the 1st, they use the full month.
    if (checkInDate.day == 1) {
      return monthlyRent.roundToDouble();
    }
    
    final daysInMonth = _daysInMonth(checkInDate);
    final dailyRent = calculateDailyRent(monthlyRent, daysInMonth);
    final remainingDays = daysRemainingInMonth(checkInDate);
    
    return (dailyRent * remainingDays).roundToDouble();
  }

  /// Calculates the prorated rent for the final checkout month based on the checkout date.
  /// Checkout calculations should ONLY calculate Current Month.
  static double calculateCurrentMonthRent(double monthlyRent, DateTime checkOutDate) {
    final daysInMonth = _daysInMonth(checkOutDate);
    
    // If checkout occurs on the last day of the month, charge the full monthly rent.
    if (checkOutDate.day == daysInMonth) {
      return monthlyRent.roundToDouble();
    }
    
    final dailyRent = calculateDailyRent(monthlyRent, daysInMonth);
    final usedDays = daysUsedInCurrentMonth(checkOutDate);
    
    return (dailyRent * usedDays).roundToDouble();
  }

  /// Calculates daily rent based on the number of days in the month.
  static double calculateDailyRent(double monthlyRent, int daysInMonth) {
    if (daysInMonth <= 0) return 0.0;
    return monthlyRent / daysInMonth;
  }

  /// Returns the number of days from the given date to the end of the month (inclusive).
  static int daysRemainingInMonth(DateTime date) {
    final endOfMonth = DateTime(date.year, date.month + 1, 0); 
    return endOfMonth.day - date.day + 1;
  }

  /// Returns the number of days used in the current month up to and including the given date.
  static int daysUsedInCurrentMonth(DateTime date) {
    return date.day;
  }

  /// Helper to get total days in a given month.
  static int _daysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }
}
