import 'package:equatable/equatable.dart';

import 'user_role.dart';

class UserEntity extends Equatable {
  final int? id;
  final String name;
  final String phone;
  final String email;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;

  const UserEntity({
    this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    this.isActive = true,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        email,
        role,
        isActive,
        createdAt,
      ];
}
