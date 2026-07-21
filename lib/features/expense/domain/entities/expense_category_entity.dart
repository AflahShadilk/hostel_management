import 'package:equatable/equatable.dart';

class ExpenseCategoryEntity extends Equatable {
  final int? id;
  final String name;
  final String? description;
  final bool isActive;
  final bool isDefault;
  final DateTime createdAt;

  const ExpenseCategoryEntity({
    this.id,
    required this.name,
    this.description,
    required this.isActive,
    this.isDefault = false,
    required this.createdAt,
  });

  @override
  List<Object?> get props => <Object?>[
        id,
        name,
        description,
        isActive,
        isDefault,
        createdAt,
      ];
}
