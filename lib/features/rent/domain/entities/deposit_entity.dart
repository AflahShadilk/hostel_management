import 'package:equatable/equatable.dart';

class DepositEntity extends Equatable {
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

  const DepositEntity({
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

  @override
  List<Object?> get props => [
        id,
        stayId,
        amount,
        refundedAmount,
        receivedDate,
        refundDate,
        paymentMethod,
        notes,
        status,
        createdAt,
        updatedAt,
      ];
}
