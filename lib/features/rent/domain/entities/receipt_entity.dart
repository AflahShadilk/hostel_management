import 'package:equatable/equatable.dart';

class ReceiptEntity extends Equatable {
  final int? id;
  final int paymentId;
  final String receiptNumber;
  final double paymentAmountSnapshot;
  final String paymentMethodSnapshot;
  final DateTime issuedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReceiptEntity({
    this.id,
    required this.paymentId,
    required this.receiptNumber,
    required this.paymentAmountSnapshot,
    required this.paymentMethodSnapshot,
    required this.issuedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        paymentId,
        receiptNumber,
        paymentAmountSnapshot,
        paymentMethodSnapshot,
        issuedAt,
        createdAt,
        updatedAt,
      ];
}
