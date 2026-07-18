import '../../domain/entities/room_entity.dart';
import '../../domain/entities/room_type.dart';
import '../../domain/entities/room_status.dart';

class RoomModel extends RoomEntity {
  const RoomModel({
    super.id,
    required super.hostelId,
    required super.roomNumber,
    required super.floor,
    required super.roomType,
    required super.numberOfBeds,
    required super.monthlyRent,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
  });

  factory RoomModel.fromEntity(RoomEntity entity) {
    return RoomModel(
      id: entity.id,
      hostelId: entity.hostelId,
      roomNumber: entity.roomNumber,
      floor: entity.floor,
      roomType: entity.roomType,
      numberOfBeds: entity.numberOfBeds,
      monthlyRent: entity.monthlyRent,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory RoomModel.fromMap(Map<String, dynamic> map) {
    return RoomModel(
      id: map['id'] as int?,
      hostelId: map['hostel_id'] as int,
      roomNumber: map['room_number'] as String,
      floor: map['floor'] as String,
      roomType: RoomType.fromDatabaseValue(map['room_type'] as String) ??
          RoomType.other,
      numberOfBeds: map['number_of_beds'] as int,
      monthlyRent: (map['monthly_rent'] as num).toDouble(),
      status: RoomStatus.fromDatabaseValue(map['status'] as String) ??
          RoomStatus.inactive,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'hostel_id': hostelId,
      'room_number': roomNumber,
      'floor': floor,
      'room_type': roomType.databaseValue,
      'number_of_beds': numberOfBeds,
      'monthly_rent': monthlyRent,
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
