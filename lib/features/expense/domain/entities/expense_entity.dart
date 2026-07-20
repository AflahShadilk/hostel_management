import 'package:equatable/equatable.dart';

class ExpenseEntity extends Equatable {
  final int? id;
  final int categoryId;
  final String title;
  final String? description;
  final double amount;
  final DateTime expenseDate;
  final String paymentMethod;
  final String? referenceNumber;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExpenseEntity({
    this.id,
    required this.categoryId,
    required this.title,
    this.description,
    required this.amount,
    required this.expenseDate,
    required this.paymentMethod,
    this.referenceNumber,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => <Object?>[
        id,
        categoryId,
        title,
        description,
        amount,
        expenseDate,
        paymentMethod,
        referenceNumber,
        notes,
        createdAt,
        updatedAt,
      ];
}
