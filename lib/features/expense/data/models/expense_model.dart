import '../../domain/entities/expense_entity.dart';

class ExpenseModel extends ExpenseEntity {
  const ExpenseModel({
    super.id,
    required super.categoryId,
    required super.title,
    super.description,
    required super.amount,
    required super.expenseDate,
    required super.paymentMethod,
    super.referenceNumber,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ExpenseModel.fromEntity(ExpenseEntity entity) {
    return ExpenseModel(
      id: entity.id,
      categoryId: entity.categoryId,
      title: entity.title,
      description: entity.description,
      amount: entity.amount,
      expenseDate: entity.expenseDate,
      paymentMethod: entity.paymentMethod,
      referenceNumber: entity.referenceNumber,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as int?,
      categoryId: map['category_id'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      amount: (map['amount'] as num).toDouble(),
      expenseDate: DateTime.parse(map['expense_date'] as String),
      paymentMethod: map['payment_method'] as String,
      referenceNumber: map['reference_number'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'category_id': categoryId,
      'title': title,
      'description': description,
      'amount': amount,
      'expense_date': expenseDate.toIso8601String(),
      'payment_method': paymentMethod,
      'reference_number': referenceNumber,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }
}
