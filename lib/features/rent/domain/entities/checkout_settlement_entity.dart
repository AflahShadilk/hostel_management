import 'package:equatable/equatable.dart';

class CheckoutSettlementEntity extends Equatable {
  final int? id;
  final int stayId;
  final double outstandingAmount;
  final double currentMonthCharge;
  final double rentDue;
  final double lateFee;
  final double otherCharges;
  final double damageCharges;
  final double depositAdjustment;
  final double refundAmount;
  final double finalAmount;
  final DateTime? settlementDate;
  final String? notes;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CheckoutSettlementEntity({
    this.id,
    required this.stayId,
    required this.outstandingAmount,
    required this.currentMonthCharge,
    required this.rentDue,
    required this.lateFee,
    this.otherCharges = 0,
    required this.damageCharges,
    required this.depositAdjustment,
    required this.refundAmount,
    required this.finalAmount,
    this.settlementDate,
    this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        stayId,
        outstandingAmount,
        currentMonthCharge,
        rentDue,
        lateFee,
        otherCharges,
        damageCharges,
        depositAdjustment,
        refundAmount,
        finalAmount,
        settlementDate,
        notes,
        status,
        createdAt,
        updatedAt,
      ];
}
