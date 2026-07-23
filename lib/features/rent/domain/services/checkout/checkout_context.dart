import '../../entities/deposit_entity.dart';
import '../../entities/rent_record_entity.dart';

/// Bundles all data required by checkout calculators.
/// Populated by the datasource (via the repository) and passed to calculator classes.
/// Contains no business logic.
class CheckoutContext {
  final int stayId;
  final int tenantId;
  final int bedId;
  final int roomId;
  final DateTime checkInDate;
  final double monthlyRent;
  final DateTime checkoutDate;
  final List<RentRecordEntity> rentRecords;
  final DepositEntity? heldDeposit;

  const CheckoutContext({
    required this.stayId,
    required this.tenantId,
    required this.bedId,
    required this.roomId,
    required this.checkInDate,
    required this.monthlyRent,
    required this.checkoutDate,
    required this.rentRecords,
    this.heldDeposit,
  });
}
