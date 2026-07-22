import '../../domain/entities/checkout_settlement_entity.dart';

class CheckoutSettlementModel {
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

  const CheckoutSettlementModel({
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

  factory CheckoutSettlementModel.fromMap(Map<String, dynamic> map) {
    return CheckoutSettlementModel(
      id: map['id'] as int?,
      stayId: map['stay_id'] as int,
      outstandingAmount: (map['outstanding_amount'] as num).toDouble(),
      currentMonthCharge: (map['current_month_charge'] as num? ?? 0).toDouble(),
      rentDue: (map['rent_due'] as num).toDouble(),
      lateFee: (map['late_fee'] as num).toDouble(),
      otherCharges: (map['other_charges'] as num? ?? 0).toDouble(),
      damageCharges: (map['damage_charges'] as num).toDouble(),
      depositAdjustment: (map['deposit_adjustment'] as num).toDouble(),
      refundAmount: (map['refund_amount'] as num).toDouble(),
      finalAmount: (map['final_amount'] as num).toDouble(),
      settlementDate: map['settlement_date'] == null
          ? null
          : DateTime.parse(map['settlement_date'] as String),
      notes: map['notes'] as String?,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  factory CheckoutSettlementModel.fromEntity(
    CheckoutSettlementEntity entity,
  ) {
    return CheckoutSettlementModel(
      id: entity.id,
      stayId: entity.stayId,
      outstandingAmount: entity.outstandingAmount,
      currentMonthCharge: entity.currentMonthCharge,
      rentDue: entity.rentDue,
      lateFee: entity.lateFee,
      otherCharges: entity.otherCharges,
      damageCharges: entity.damageCharges,
      depositAdjustment: entity.depositAdjustment,
      refundAmount: entity.refundAmount,
      finalAmount: entity.finalAmount,
      settlementDate: entity.settlementDate,
      notes: entity.notes,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'stay_id': stayId,
      'outstanding_amount': outstandingAmount,
      'current_month_charge': currentMonthCharge,
      'rent_due': rentDue,
      'late_fee': lateFee,
      'other_charges': otherCharges,
      'damage_charges': damageCharges,
      'deposit_adjustment': depositAdjustment,
      'refund_amount': refundAmount,
      'final_amount': finalAmount,
      'settlement_date': settlementDate?.toIso8601String(),
      'notes': notes,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    if (id != null) map['id'] = id;
    return map;
  }

  CheckoutSettlementEntity toEntity() {
    return CheckoutSettlementEntity(
      id: id,
      stayId: stayId,
      outstandingAmount: outstandingAmount,
      currentMonthCharge: currentMonthCharge,
      rentDue: rentDue,
      lateFee: lateFee,
      otherCharges: otherCharges,
      damageCharges: damageCharges,
      depositAdjustment: depositAdjustment,
      refundAmount: refundAmount,
      finalAmount: finalAmount,
      settlementDate: settlementDate,
      notes: notes,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
