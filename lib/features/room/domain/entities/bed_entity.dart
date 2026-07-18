import 'package:equatable/equatable.dart';
import 'bed_status.dart';

class BedEntity extends Equatable {
  final int? id;
  final int roomId;
  final String bedNumber;
  final BedStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BedEntity({
    this.id,
    required this.roomId,
    required this.bedNumber,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        roomId,
        bedNumber,
        status,
        createdAt,
        updatedAt,
      ];
}
