import 'package:equatable/equatable.dart';

import 'rent_record_entity.dart';

/// Aggregates a [RentRecordEntity] with its associated stay details for the Collection Center.
class RentCollectionItemEntity extends Equatable {
  final RentRecordEntity rentRecord;
  final int tenantId;
  final String tenantName;
  final String roomNumber;
  final String bedNumber;

  const RentCollectionItemEntity({
    required this.rentRecord,
    required this.tenantId,
    required this.tenantName,
    required this.roomNumber,
    required this.bedNumber,
  });

  @override
  List<Object?> get props => [
        rentRecord,
        tenantId,
        tenantName,
        roomNumber,
        bedNumber,
      ];
}
