import 'rent_record_model.dart';
import 'deposit_model.dart';
import 'stay_model.dart';

/// Raw database data loaded by the datasource for a checkout operation.
///
/// Passed to the repository so it can build a [CheckoutContext]
/// and hand it to the calculator layer.
class CheckoutDataBundle {
  final StayModel stay;
  final List<RentRecordModel> rentRecords;
  final DepositModel? heldDeposit;

  const CheckoutDataBundle({
    required this.stay,
    required this.rentRecords,
    this.heldDeposit,
  });
}
