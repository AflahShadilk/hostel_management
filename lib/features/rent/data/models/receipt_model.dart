import '../../domain/entities/receipt_entity.dart';

class ReceiptModel {
  final int? id;
  final int paymentId;
  final String receiptNumber;
  final double paymentAmountSnapshot;
  final String paymentMethodSnapshot;
  final DateTime issuedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReceiptModel({
    this.id,
    required this.paymentId,
    required this.receiptNumber,
    required this.paymentAmountSnapshot,
    required this.paymentMethodSnapshot,
    required this.issuedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReceiptModel.fromMap(Map<String, dynamic> map) {
    return ReceiptModel(
      id: map['id'] as int?,
      paymentId: map['payment_id'] as int,
      receiptNumber: map['receipt_number'] as String,
      paymentAmountSnapshot: (map['payment_amount_snapshot'] as num).toDouble(),
      paymentMethodSnapshot: map['payment_method_snapshot'] as String,
      issuedAt: DateTime.parse(map['issued_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  factory ReceiptModel.fromEntity(ReceiptEntity entity) {
    return ReceiptModel(
      id: entity.id,
      paymentId: entity.paymentId,
      receiptNumber: entity.receiptNumber,
      paymentAmountSnapshot: entity.paymentAmountSnapshot,
      paymentMethodSnapshot: entity.paymentMethodSnapshot,
      issuedAt: entity.issuedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'payment_id': paymentId,
      'receipt_number': receiptNumber,
      'payment_amount_snapshot': paymentAmountSnapshot,
      'payment_method_snapshot': paymentMethodSnapshot,
      'issued_at': issuedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    if (id != null) map['id'] = id;
    return map;
  }

  ReceiptEntity toEntity() {
    return ReceiptEntity(
      id: id,
      paymentId: paymentId,
      receiptNumber: receiptNumber,
      paymentAmountSnapshot: paymentAmountSnapshot,
      paymentMethodSnapshot: paymentMethodSnapshot,
      issuedAt: issuedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
