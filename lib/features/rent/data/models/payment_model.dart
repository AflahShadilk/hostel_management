import '../../domain/entities/payment_entity.dart';

class PaymentModel {
  final int? id;
  final int rentRecordId;
  final int stayId;
  final int tenantId;
  final double amount;
  final DateTime paymentDate;
  final String paymentMethod;
  final String receiptNumber;
  final String? notes;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PaymentModel({
    this.id,
    required this.rentRecordId,
    required this.stayId,
    required this.tenantId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    required this.receiptNumber,
    this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] as int?,
      rentRecordId: map['rent_record_id'] as int,
      stayId: map['stay_id'] as int,
      tenantId: map['tenant_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(map['payment_date'] as String),
      paymentMethod: map['payment_method'] as String,
      receiptNumber: map['receipt_number'] as String,
      notes: map['notes'] as String?,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  factory PaymentModel.fromEntity(PaymentEntity entity) {
    return PaymentModel(
      id: entity.id,
      rentRecordId: entity.rentRecordId,
      stayId: entity.stayId,
      tenantId: entity.tenantId,
      amount: entity.amount,
      paymentDate: entity.paymentDate,
      paymentMethod: entity.paymentMethod,
      receiptNumber: entity.receiptNumber,
      notes: entity.notes,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'rent_record_id': rentRecordId,
      'stay_id': stayId,
      'tenant_id': tenantId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
      'payment_method': paymentMethod,
      'receipt_number': receiptNumber,
      'notes': notes,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    if (id != null) map['id'] = id;
    return map;
  }

  PaymentEntity toEntity() {
    return PaymentEntity(
      id: id,
      rentRecordId: rentRecordId,
      stayId: stayId,
      tenantId: tenantId,
      amount: amount,
      paymentDate: paymentDate,
      paymentMethod: paymentMethod,
      receiptNumber: receiptNumber,
      notes: notes,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
