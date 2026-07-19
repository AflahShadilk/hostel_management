import 'package:equatable/equatable.dart';

class DamageChargeEntity extends Equatable {
  final int? id;
  final int stayId;
  final String description;
  final double amount;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DamageChargeEntity({
    this.id,
    required this.stayId,
    required this.description,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        stayId,
        description,
        amount,
        status,
        createdAt,
        updatedAt,
      ];
}
