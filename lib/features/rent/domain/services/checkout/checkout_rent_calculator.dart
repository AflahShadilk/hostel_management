import '../../constants/rent_status_constants.dart';
import '../../utils/rent_calculator.dart';
import 'checkout_context.dart';
import 'checkout_rent_result.dart';

/// Calculates all rent-related figures for a checkout settlement.
///
/// Responsibilities:
/// - Prorated charge for the checkout month (delegates to [RentCalculator]).
/// - Effective start date for the current-month rent record.
/// - Total outstanding rent across all months since check-in.
/// - Previous-months outstanding rent (excluding checkout month).
///
/// Does NOT access SQLite. Does NOT update any records.
class CheckoutRentCalculator {
  const CheckoutRentCalculator._();

  /// Computes rent figures from [ctx].
  ///
  /// [ctx.rentRecords] must reflect the state BEFORE the current-month record
  /// is upserted. The calculator aggregates outstanding amounts and computes
  /// the new [currentMonthCharge] from the existing rent records.
  static CheckoutRentResult calculate(CheckoutContext ctx) {
    final checkoutDate = ctx.checkoutDate;
    final firstDayOfMonth = DateTime(checkoutDate.year, checkoutDate.month, 1);

    // --- Current month prorated charge ---
    final currentMonthCharge = RentCalculator.calculateCurrentMonthRent(
      ctx.monthlyRent,
      checkoutDate,
      checkInDate: ctx.checkInDate,
    );

    // Effective start date for the current-month rent record.
    final cleanCheckIn = DateTime(
      ctx.checkInDate.year,
      ctx.checkInDate.month,
      ctx.checkInDate.day,
    );
    final effectiveStartDate =
        cleanCheckIn.isAfter(firstDayOfMonth) ? cleanCheckIn : firstDayOfMonth;

    // --- Outstanding rent aggregation ---
    final currentMonthPrefix =
        '${checkoutDate.year}-${checkoutDate.month.toString().padLeft(2, '0')}';

    final checkInMonthStart =
        DateTime(ctx.checkInDate.year, ctx.checkInDate.month, 1);

    double previousPendingRent = 0;
    double currentMonthPaid = 0;

    for (final record in ctx.rentRecords) {
      // Skip records before check-in month (safety guard).
      if (record.startDate.isBefore(checkInMonthStart)) continue;

      final isCurrent =
          record.startDate.toIso8601String().startsWith(currentMonthPrefix);

      if (isCurrent) {
        currentMonthPaid = record.amountPaid;
      } else {
        previousPendingRent +=
            (record.amountDue - record.amountPaid).clamp(0, double.infinity);
      }
    }

    // Net outstanding for current month = prorated charge − already paid.
    final currentMonthOutstanding =
        (currentMonthCharge - currentMonthPaid).clamp(0, double.infinity);

    final totalPendingRent = previousPendingRent + currentMonthOutstanding;

    final currentMonthRentStatus = currentMonthPaid >= currentMonthCharge
        ? RentStatus.paid
        : RentStatus.pending;

    return CheckoutRentResult(
      currentMonthCharge: currentMonthCharge,
      currentMonthPaid: currentMonthPaid,
      currentMonthRentStatus: currentMonthRentStatus,
      effectiveStartDate: effectiveStartDate,
      totalPendingRent: totalPendingRent,
      previousPendingRent: previousPendingRent,
    );
  }
}
