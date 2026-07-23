// lib/features/rent/domain/utils/rent_calculator.dart

class RentCalculator {
  /// Calculates the prorated rent for the first month based on the check-in date.
  /// The FIRST month is always prorated.
  static double calculateFirstMonthRent(
      double monthlyRent, DateTime checkInDate) {
    // If checking in on the 1st, they use the full month.
    if (checkInDate.day == 1) {
      return monthlyRent.roundToDouble();
    }

    final daysInMonth = _daysInMonth(checkInDate);
    final dailyRent = calculateDailyRent(monthlyRent, daysInMonth);
    final remainingDays = daysRemainingInMonth(checkInDate);

    return (dailyRent * remainingDays).roundToDouble();
  }

  /// Calculates the prorated rent for the final checkout month based on the checkout date
  /// and optional tenant check-in date.
  ///
  /// REQUIRED BUSINESS RULE:
  /// If the tenant checked in during the current month, the current month's prorated rent
  /// MUST start from the tenant's actual check-in date.
  ///
  /// If the tenant checked in before the current month (or if checkInDate is null),
  /// the calculation begins from the 1st day of the current month.
  ///
  /// effectiveStartDate = max(checkInDate, firstDayOfCurrentMonth)
  /// effectiveEndDate = checkOutDate
  /// Chargeable days = inclusive difference between effectiveStartDate and effectiveEndDate.
  static double calculateCurrentMonthRent(
    double monthlyRent,
    DateTime checkOutDate, {
    DateTime? checkInDate,
  }) {
    final daysInMonth = _daysInMonth(checkOutDate);
    final usedDays = daysUsedInCurrentMonth(
      checkOutDate,
      checkInDate: checkInDate,
    );

    if (usedDays <= 0) return 0.0;

    // If tenant stayed all days of the month, charge full monthly rent.
    if (usedDays == daysInMonth) {
      return monthlyRent.roundToDouble();
    }

    final dailyRent = calculateDailyRent(monthlyRent, daysInMonth);
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

  /// Returns the number of chargeable days used in the current month up to and
  /// including [checkOutDate], starting from [checkInDate] (if checked in during the
  /// current month) or the 1st of the current month.
  static int daysUsedInCurrentMonth(
    DateTime checkOutDate, {
    DateTime? checkInDate,
  }) {
    final firstDayOfCurrentMonth =
        DateTime(checkOutDate.year, checkOutDate.month, 1);
    final cleanCheckout =
        DateTime(checkOutDate.year, checkOutDate.month, checkOutDate.day);

    DateTime effectiveStartDate = firstDayOfCurrentMonth;
    if (checkInDate != null) {
      final cleanCheckIn =
          DateTime(checkInDate.year, checkInDate.month, checkInDate.day);
      if (cleanCheckIn.isAfter(firstDayOfCurrentMonth)) {
        effectiveStartDate = cleanCheckIn;
      }
    }

    if (cleanCheckout.isBefore(effectiveStartDate)) {
      return 0;
    }

    return cleanCheckout.day - effectiveStartDate.day + 1;
  }

  /// Helper to get total days in a given month.
  static int _daysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }
}
