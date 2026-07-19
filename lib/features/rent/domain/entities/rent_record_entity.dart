import 'package:equatable/equatable.dart';

class RentRecordEntity extends Equatable {
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

  const RentRecordEntity({
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

  @override
  List<Object?> get props => [
        id,
        stayId,
        billingMonth,
        billingYear,
        rentPeriod,
        dueDate,
        generatedAt,
        amountDue,
        amountPaid,
        status,
        createdAt,
        updatedAt,
      ];
}
