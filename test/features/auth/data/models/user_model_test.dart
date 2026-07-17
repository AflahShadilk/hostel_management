import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_management/features/auth/data/models/user_model.dart';
import 'package:hostel_management/features/auth/domain/entities/user_entity.dart';
import 'package:hostel_management/features/auth/domain/entities/user_role.dart';

void main() {
  group('UserRole', () {
    test('databaseValue maps correctly', () {
      expect(UserRole.owner.databaseValue, 'owner');
      expect(UserRole.manager.databaseValue, 'manager');
    });

    test('fromDatabaseValue parses valid values', () {
      expect(UserRole.fromDatabaseValue('owner'), UserRole.owner);
      expect(UserRole.fromDatabaseValue('manager'), UserRole.manager);
    });

    test('fromDatabaseValue returns null for invalid values', () {
      expect(UserRole.fromDatabaseValue('admin'), isNull);
      expect(UserRole.fromDatabaseValue(''), isNull);
    });
  });

  group('UserModel Serialization', () {
    final tDate = DateTime(2023, 10, 1, 12, 0, 0);
    final tUserEntity = UserEntity(
      id: 1,
      name: 'Test Owner',
      phone: '1234567890',
      email: 'test@example.com',
      role: UserRole.owner,
      isActive: true,
      createdAt: tDate,
    );

    final tUserMap = {
      'id': 1,
      'name': 'Test Owner',
      'phone': '1234567890',
      'email': 'test@example.com',
      'role': 'owner',
      'is_active': 1,
      'created_at': tDate.toIso8601String(),
    };

    test('toMap converts entity to map correctly', () {
      final result = UserModel.toMap(tUserEntity);
      expect(result, tUserMap);
    });

    test('fromMap converts map to entity correctly', () {
      final result = UserModel.fromMap(tUserMap);
      expect(result, tUserEntity);
    });

    test('fromMap handles invalid role safely by defaulting to owner', () {
      final map = Map<String, dynamic>.from(tUserMap)..['role'] = 'invalid';
      final result = UserModel.fromMap(map);
      expect(result.role, UserRole.owner);
    });

    test('fromMap parses is_active 0 to false', () {
      final map = Map<String, dynamic>.from(tUserMap)..['is_active'] = 0;
      final result = UserModel.fromMap(map);
      expect(result.isActive, isFalse);
    });
  });
}
