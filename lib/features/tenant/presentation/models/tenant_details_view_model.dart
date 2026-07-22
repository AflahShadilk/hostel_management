import '../../domain/entities/tenant_entity.dart';
import '../../../rent/domain/entities/deposit_entity.dart';
import '../../../rent/domain/entities/stay_entity.dart';

/// Read-only composition used by the Tenant Details presentation.
class TenantDetailsViewModel {
  const TenantDetailsViewModel({
    required this.tenant,
    required this.stay,
    required this.roomName,
    required this.bedName,
    this.deposit,
  });

  final TenantEntity tenant;
  final StayEntity? stay;
  final String? roomName;
  final String? bedName;
  final DepositEntity? deposit;
}
