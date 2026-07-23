/// Aggregated financial result for a checkout settlement.
///
/// Produced by [CheckoutDepositCalculator] and passed to the datasource
/// to persist the settlement record.
class CheckoutSettlementResult {
  /// Prorated charge for the checkout month.
  final double currentMonthCharge;

  /// Outstanding rent across ALL months (previous + current).
  final double totalPendingRent;

  /// Outstanding rent from months BEFORE the checkout month.
  final double previousPendingRent;

  /// Total amount owed by tenant:
  /// totalPendingRent + damageAmount + otherCharges
  final double totalDue;

  /// Portion of the held deposit applied against totalDue.
  final double depositAdjustment;

  /// Amount refunded to the tenant (deposit − totalDue, if positive).
  final double refundAmount;

  /// Amount still owed by the tenant after deposit is applied (if any).
  final double remainingAmount;

  /// Status of deposit after settlement ('refunded' or 'forfeited').
  final String depositStatus;

  const CheckoutSettlementResult({
    required this.currentMonthCharge,
    required this.totalPendingRent,
    required this.previousPendingRent,
    required this.totalDue,
    required this.depositAdjustment,
    required this.refundAmount,
    required this.remainingAmount,
    required this.depositStatus,
  });
}
