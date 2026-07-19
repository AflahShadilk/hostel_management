import 'package:equatable/equatable.dart';

class PaymentEntity extends Equatable {
  final int? id;
  final int rentRecordId;
  final double amount;
  final DateTime paymentDate;
  final String paymentMethod;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PaymentEntity({
    this.id,
    required this.rentRecordId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        rentRecordId,
        amount,
        paymentDate,
        paymentMethod,
        status,
        createdAt,
        updatedAt,
      ];
}
