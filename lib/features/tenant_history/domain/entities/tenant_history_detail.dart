import 'package:equatable/equatable.dart';

import '../../../rent/domain/entities/checkout_settlement_entity.dart';
import '../../../rent/domain/entities/deposit_entity.dart';
import '../../../rent/domain/entities/payment_entity.dart';
import '../../../rent/domain/entities/rent_record_entity.dart';
import '../../../rent/domain/entities/stay_entity.dart';
import '../../../tenant/domain/entities/tenant_entity.dart';

/// Comprehensive aggregate root for a completed stay's details.
class TenantHistoryDetail extends Equatable {
  final StayEntity stay;
  final TenantEntity tenant;
  final List<RentRecordEntity> rentRecords;
  final List<PaymentEntity> payments;
  final DepositEntity? deposit;
  final CheckoutSettlementEntity? checkoutSettlement;

  const TenantHistoryDetail({
    required this.stay,
    required this.tenant,
    required this.rentRecords,
    required this.payments,
    this.deposit,
    this.checkoutSettlement,
  });

  /// The duration of the stay in days (inclusive of check-in and check-out days).
  int get totalStayDays {
    if (stay.checkOutDate == null) return 0;
    return stay.checkOutDate!.difference(stay.checkInDate).inDays + 1;
  }

  @override
  List<Object?> get props => [
        stay,
        tenant,
        rentRecords,
        payments,
        deposit,
        checkoutSettlement,
      ];
}
