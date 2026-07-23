import '../../domain/services/checkout/checkout_settlement_result.dart';
import 'upsert_rent_record_command.dart';

/// Parameters for the datasource's [persistCheckout] transaction.
///
/// The datasource uses this to:
/// 1. Insert the checkout_settlements row.
/// 2. Insert a damage_charges row (if damageAmount > 0).
/// 3. Update the deposits row (refund / forfeit).
/// 4. Mark the stay as checked-out.
/// 5. Update the tenant record (status, bed).
/// 6. Update bed status to vacant.
/// 7. Recalculate room occupancy status.
class PersistCheckoutCommand {
  final int stayId;
  final int tenantId;
  final int bedId;
  final int roomId;
  final DateTime checkoutDate;
  final String? notes;
  final double damageAmount;
  final double otherCharges;

  /// Fully computed settlement figures from [CheckoutDepositCalculator].
  final CheckoutSettlementResult settlement;

  /// ID of the held deposit row to update, or null if no deposit was held.
  final int? depositId;

  /// Current-month rent write persisted with the settlement transaction.
  final UpsertRentRecordCommand currentMonthRentRecord;

  const PersistCheckoutCommand({
    required this.stayId,
    required this.tenantId,
    required this.bedId,
    required this.roomId,
    required this.checkoutDate,
    this.notes,
    required this.damageAmount,
    required this.otherCharges,
    required this.settlement,
    this.depositId,
    required this.currentMonthRentRecord,
  });
}
