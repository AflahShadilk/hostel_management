import '../../domain/entities/user_entity.dart';
import '../../domain/entities/user_role.dart';

class UserModel {
  const UserModel._();

  static UserEntity fromMap(Map<String, dynamic> map) {
    return UserEntity(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String,
      role: UserRole.fromDatabaseValue(map['role'] as String) ??
          UserRole
              .owner, // Defaulting as a fallback, though schema should prevent invalid values
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  static Map<String, dynamic> toMap(UserEntity entity) {
    return {
      if (entity.id != null) 'id': entity.id,
      'name': entity.name,
      'phone': entity.phone,
      'email': entity.email,
      'role': entity.role.databaseValue,
      'is_active': entity.isActive ? 1 : 0,
      'created_at': entity.createdAt.toIso8601String(),
    };
  }
}
