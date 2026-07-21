import '../../domain/entities/deposit_entity.dart';

class DepositModel {
  final int? id;
  final int stayId;
  final double amount;
  final double refundedAmount;
  final DateTime receivedDate;
  final DateTime? refundDate;
  final String paymentMethod;
  final String? notes;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DepositModel({
    this.id,
    required this.stayId,
    required this.amount,
    required this.refundedAmount,
    required this.receivedDate,
    this.refundDate,
    this.paymentMethod = '',
    this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DepositModel.fromMap(Map<String, dynamic> map) {
    return DepositModel(
      id: map['id'] as int?,
      stayId: map['stay_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      refundedAmount: (map['refunded_amount'] as num).toDouble(),
      receivedDate: DateTime.parse(map['received_date'] as String),
      refundDate: map['refund_date'] == null
          ? null
          : DateTime.parse(map['refund_date'] as String),
      paymentMethod: map['payment_method'] as String? ?? '',
      notes: map['notes'] as String?,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  factory DepositModel.fromEntity(DepositEntity entity) {
    return DepositModel(
      id: entity.id,
      stayId: entity.stayId,
      amount: entity.amount,
      refundedAmount: entity.refundedAmount,
      receivedDate: entity.receivedDate,
      refundDate: entity.refundDate,
      paymentMethod: entity.paymentMethod,
      notes: entity.notes,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'stay_id': stayId,
      'amount': amount,
      'received_date': receivedDate.toIso8601String(),
      'refund_date': refundDate?.toIso8601String(),
      'refunded_amount': refundedAmount,
      'payment_method': paymentMethod,
      'notes': notes,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    if (id != null) map['id'] = id;
    return map;
  }

  DepositEntity toEntity() {
    return DepositEntity(
      id: id,
      stayId: stayId,
      amount: amount,
      refundedAmount: refundedAmount,
      receivedDate: receivedDate,
      refundDate: refundDate,
      paymentMethod: paymentMethod,
      notes: notes,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
