import 'package:equatable/equatable.dart';

class CheckoutSettlementEntity extends Equatable {
  final int? id;
  final int stayId;
  final double outstandingAmount;
  final double rentDue;
  final double lateFee;
  final double damageCharges;
  final double depositAdjustment;
  final double refundAmount;
  final double finalAmount;
  final DateTime? settlementDate;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CheckoutSettlementEntity({
    this.id,
    required this.stayId,
    required this.outstandingAmount,
    required this.rentDue,
    required this.lateFee,
    required this.damageCharges,
    required this.depositAdjustment,
    required this.refundAmount,
    required this.finalAmount,
    this.settlementDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        stayId,
        outstandingAmount,
        rentDue,
        lateFee,
        damageCharges,
        depositAdjustment,
        refundAmount,
        finalAmount,
        settlementDate,
        status,
        createdAt,
        updatedAt,
      ];
}
