import 'package:equatable/equatable.dart';

class PaymentEntity extends Equatable {
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

  const PaymentEntity({
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

  @override
  List<Object?> get props => [
        id,
        rentRecordId,
        stayId,
        tenantId,
        amount,
        paymentDate,
        paymentMethod,
        receiptNumber,
        notes,
        status,
        createdAt,
        updatedAt,
      ];
}
