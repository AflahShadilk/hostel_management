import '../../domain/entities/stay_entity.dart';

class StayModel {
  final int? id;
  final int tenantId;
  final int roomId;
  final int bedId;
  final DateTime checkInDate;
  final DateTime? checkOutDate;
  final DateTime? expectedCheckoutDate;
  final double monthlyRentSnapshot;
  final double dailyRate;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StayModel({
    this.id,
    required this.tenantId,
    required this.roomId,
    required this.bedId,
    required this.checkInDate,
    this.checkOutDate,
    this.expectedCheckoutDate,
    required this.monthlyRentSnapshot,
    required this.dailyRate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StayModel.fromMap(Map<String, dynamic> map) {
    return StayModel(
      id: map['id'] as int?,
      tenantId: map['tenant_id'] as int,
      roomId: map['room_id'] as int,
      bedId: map['bed_id'] as int,
      checkInDate: DateTime.parse(map['check_in_date'] as String),
      checkOutDate: map['check_out_date'] == null
          ? null
          : DateTime.parse(map['check_out_date'] as String),
      expectedCheckoutDate: map['expected_checkout_date'] == null
          ? null
          : DateTime.parse(map['expected_checkout_date'] as String),
      monthlyRentSnapshot: (map['monthly_rent_snapshot'] as num).toDouble(),
      dailyRate: (map['daily_rate'] as num).toDouble(),
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  factory StayModel.fromEntity(StayEntity entity) {
    return StayModel(
      id: entity.id,
      tenantId: entity.tenantId,
      roomId: entity.roomId,
      bedId: entity.bedId,
      checkInDate: entity.checkInDate,
      checkOutDate: entity.checkOutDate,
      expectedCheckoutDate: entity.expectedCheckoutDate,
      monthlyRentSnapshot: entity.monthlyRentSnapshot,
      dailyRate: entity.dailyRate,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'tenant_id': tenantId,
      'room_id': roomId,
      'bed_id': bedId,
      'check_in_date': checkInDate.toIso8601String(),
      'check_out_date': checkOutDate?.toIso8601String(),
      'expected_checkout_date': expectedCheckoutDate?.toIso8601String(),
      'monthly_rent_snapshot': monthlyRentSnapshot,
      'daily_rate': dailyRate,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    if (id != null) map['id'] = id;
    return map;
  }

  StayEntity toEntity() {
    return StayEntity(
      id: id,
      tenantId: tenantId,
      roomId: roomId,
      bedId: bedId,
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
      expectedCheckoutDate: expectedCheckoutDate,
      monthlyRentSnapshot: monthlyRentSnapshot,
      dailyRate: dailyRate,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
