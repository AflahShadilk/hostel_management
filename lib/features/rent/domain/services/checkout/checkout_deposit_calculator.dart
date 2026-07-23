import 'checkout_rent_result.dart';
import 'checkout_settlement_result.dart';

/// Applies the security deposit against the total amount due and
/// produces the final settlement amounts.
///
/// BUSINESS RULE:
/// The security deposit is completely independent from rent calculation.
/// It is only applied AFTER all rent, damage, and other charges are totalled.
///
/// Does NOT access SQLite. Does NOT modify any state.
class CheckoutDepositCalculator {
  const CheckoutDepositCalculator._();

  /// Validates inputs for damageAmount and otherCharges.
  static void validateCharges({
    required double damageAmount,
    required double otherCharges,
  }) {
    if (!damageAmount.isFinite || damageAmount < 0) {
      throw ArgumentError('Damage amount cannot be negative.');
    }
    if (!otherCharges.isFinite || otherCharges < 0) {
      throw ArgumentError('Other charges cannot be negative.');
    }
  }

  /// Calculates the final settlement amounts from [rentResult] and charges.
  ///
  /// - [rentResult] — output of [CheckoutRentCalculator.calculate].
  /// - [damageAmount] — damage charges entered by the admin.
  /// - [otherCharges] — miscellaneous charges entered by the admin.
  /// - [heldDeposit] — amount of security deposit currently held (0 if none).
  static CheckoutSettlementResult calculate({
    required CheckoutRentResult rentResult,
    required double damageAmount,
    required double otherCharges,
    required double heldDeposit,
  }) {
    validateCharges(damageAmount: damageAmount, otherCharges: otherCharges);

    final totalDue =
        rentResult.totalPendingRent + damageAmount + otherCharges;

    // Apply deposit only up to totalDue — never refund more than was held.
    final depositAdjustment = totalDue.clamp(0.0, heldDeposit);
    final refundAmount = (heldDeposit - depositAdjustment).toDouble();
    final remainingAmount = (totalDue - depositAdjustment).toDouble();
    final depositStatus = refundAmount > 0 ? 'refunded' : 'forfeited';

    return CheckoutSettlementResult(
      currentMonthCharge: rentResult.currentMonthCharge,
      totalPendingRent: rentResult.totalPendingRent,
      previousPendingRent: rentResult.previousPendingRent,
      totalDue: totalDue,
      depositAdjustment: depositAdjustment,
      refundAmount: refundAmount,
      remainingAmount: remainingAmount,
      depositStatus: depositStatus,
    );
  }
}
