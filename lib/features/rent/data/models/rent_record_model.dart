import '../../domain/entities/rent_record_entity.dart';

class RentRecordModel {
  final int? id;
  final int stayId;
  final int billingMonth;
  final int billingYear;
  final String rentPeriod;
  final DateTime dueDate;
  final DateTime generatedAt;
  final double amountDue;
  final double amountPaid;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RentRecordModel({
    this.id,
    required this.stayId,
    required this.billingMonth,
    required this.billingYear,
    required this.rentPeriod,
    required this.dueDate,
    required this.generatedAt,
    required this.amountDue,
    required this.amountPaid,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RentRecordModel.fromMap(Map<String, dynamic> map) {
    return RentRecordModel(
      id: map['id'] as int?,
      stayId: map['stay_id'] as int,
      billingMonth: map['billing_month'] as int,
      billingYear: map['billing_year'] as int,
      rentPeriod: map['rent_period'] as String,
      dueDate: DateTime.parse(map['due_date'] as String),
      generatedAt: DateTime.parse(map['generated_at'] as String),
      amountDue: (map['amount_due'] as num).toDouble(),
      amountPaid: (map['amount_paid'] as num).toDouble(),
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  factory RentRecordModel.fromEntity(RentRecordEntity entity) {
    return RentRecordModel(
      id: entity.id,
      stayId: entity.stayId,
      billingMonth: entity.billingMonth,
      billingYear: entity.billingYear,
      rentPeriod: entity.rentPeriod,
      dueDate: entity.dueDate,
      generatedAt: entity.generatedAt,
      amountDue: entity.amountDue,
      amountPaid: entity.amountPaid,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'stay_id': stayId,
      'billing_month': billingMonth,
      'billing_year': billingYear,
      'rent_period': rentPeriod,
      'due_date': dueDate.toIso8601String(),
      'generated_at': generatedAt.toIso8601String(),
      'amount_due': amountDue,
      'amount_paid': amountPaid,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    if (id != null) map['id'] = id;
    return map;
  }

  RentRecordEntity toEntity() {
    return RentRecordEntity(
      id: id,
      stayId: stayId,
      billingMonth: billingMonth,
      billingYear: billingYear,
      rentPeriod: rentPeriod,
      dueDate: dueDate,
      generatedAt: generatedAt,
      amountDue: amountDue,
      amountPaid: amountPaid,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
