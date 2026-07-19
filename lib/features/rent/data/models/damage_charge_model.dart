import '../../domain/entities/damage_charge_entity.dart';

class DamageChargeModel {
  final int? id;
  final int stayId;
  final String description;
  final double amount;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DamageChargeModel({
    this.id,
    required this.stayId,
    required this.description,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DamageChargeModel.fromMap(Map<String, dynamic> map) {
    return DamageChargeModel(
      id: map['id'] as int?,
      stayId: map['stay_id'] as int,
      description: map['description'] as String,
      amount: (map['amount'] as num).toDouble(),
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  factory DamageChargeModel.fromEntity(DamageChargeEntity entity) {
    return DamageChargeModel(
      id: entity.id,
      stayId: entity.stayId,
      description: entity.description,
      amount: entity.amount,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'stay_id': stayId,
      'description': description,
      'amount': amount,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    if (id != null) map['id'] = id;
    return map;
  }

  DamageChargeEntity toEntity() {
    return DamageChargeEntity(
      id: id,
      stayId: stayId,
      description: description,
      amount: amount,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
