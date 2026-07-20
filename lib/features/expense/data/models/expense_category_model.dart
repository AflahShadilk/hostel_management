import '../../domain/entities/expense_category_entity.dart';

class ExpenseCategoryModel extends ExpenseCategoryEntity {
  const ExpenseCategoryModel({
    super.id,
    required super.name,
    super.description,
    required super.isActive,
    required super.createdAt,
  });

  factory ExpenseCategoryModel.fromEntity(ExpenseCategoryEntity entity) {
    return ExpenseCategoryModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
    );
  }

  factory ExpenseCategoryModel.fromMap(Map<String, dynamic> map) {
    return ExpenseCategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'description': description,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }
}
