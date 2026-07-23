/// Result produced by [CheckoutRentCalculator].
///
/// Contains all rent-related figures needed for settlement.
class CheckoutRentResult {
  /// Prorated charge for the checkout month only.
  final double currentMonthCharge;

  /// Amount already paid towards the checkout month.
  final double currentMonthPaid;

  /// Status of the checkout month rent record ('paid' or 'pending').
  final String currentMonthRentStatus;

  /// The effective start date for the current-month rent record
  /// (max of check-in date and first day of checkout month).
  final DateTime effectiveStartDate;

  /// Outstanding rent across ALL months (including the checkout month).
  /// Used as the basis for total due.
  final double totalPendingRent;

  /// Outstanding rent from months BEFORE the checkout month.
  /// Displayed in the settlement UI as "Previous Pending Rent".
  final double previousPendingRent;

  const CheckoutRentResult({
    required this.currentMonthCharge,
    this.currentMonthPaid = 0,
    this.currentMonthRentStatus = 'pending',
    required this.effectiveStartDate,
    required this.totalPendingRent,
    required this.previousPendingRent,
  });
}
