import 'package:equatable/equatable.dart';

import '../../../rent/domain/entities/rent_record_entity.dart';
import '../../../rent/domain/entities/stay_entity.dart';
import '../../../room/domain/entities/bed_entity.dart';
import '../../../room/domain/entities/room_entity.dart';
import 'tenant_entity.dart';

/// The records created together when an active tenant is assigned to a bed.
///
/// This deliberately contains the pending rent obligation only. Deposit and
/// payment transactions are recorded later when a manager confirms them.
class TenantRegistrationContext extends Equatable {
  const TenantRegistrationContext({
    required this.tenant,
    required this.stay,
    required this.room,
    required this.bed,
    required this.initialRentRecord,
  });

  final TenantEntity tenant;
  final StayEntity stay;
  final RoomEntity room;
  final BedEntity bed;
  final RentRecordEntity initialRentRecord;

  @override
  List<Object?> get props => <Object?>[
        tenant,
        stay,
        room,
        bed,
        initialRentRecord,
      ];
}
