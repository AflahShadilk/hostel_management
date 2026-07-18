import '../../domain/entities/bed_entity.dart';
import '../../domain/entities/bed_status.dart';

class BedModel extends BedEntity {
  const BedModel({
    super.id,
    required super.roomId,
    required super.bedNumber,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
  });

  factory BedModel.fromEntity(BedEntity entity) {
    return BedModel(
      id: entity.id,
      roomId: entity.roomId,
      bedNumber: entity.bedNumber,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory BedModel.fromMap(Map<String, dynamic> map) {
    return BedModel(
      id: map['id'] as int?,
      roomId: map['room_id'] as int,
      bedNumber: map['bed_number'] as String,
      status: BedStatus.fromDatabaseValue(map['status'] as String) ??
          BedStatus.inactive,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'room_id': roomId,
      'bed_number': bedNumber,
      'status': status.databaseValue,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }
}
