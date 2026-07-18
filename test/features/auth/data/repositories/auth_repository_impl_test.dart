import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_management/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:hostel_management/features/auth/domain/entities/user_entity.dart';
import 'package:hostel_management/features/auth/domain/entities/user_role.dart';
import 'package:hostel_management/core/database/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase appDatabase;
  late AuthRepositoryImpl authRepository;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // Ensure a clean DB before the suite
    await AppDatabase.instance.close();
    appDatabase = AppDatabase.instance;
    // Open once and create schema
    final db = await appDatabase.database;
    await db.delete('users');
  });

  setUp(() async {
    appDatabase = AppDatabase.instance;
    authRepository = AuthRepositoryImpl(appDatabase);
    // Clear users table before each test for isolation
    final db = await appDatabase.database;
    await db.delete('users');
  });

  tearDownAll(() async {
    await AppDatabase.instance.close();
  });

  group('AuthRepositoryImpl', () {
    test('createUser inserts a user correctly', () async {
      final user = UserEntity(
        name: 'Test Name',
        phone: '1234567890',
        email: 'test@example.com',
        role: UserRole.owner,
        isActive: true,
        createdAt: DateTime.now(),
      );

      final result = await authRepository.createUser(user);
      expect(result.id, isNotNull);
      expect(result.name, 'Test Name');
      expect(result.phone, '1234567890');
      expect(result.email, 'test@example.com');
    });

    test('createUser throws StateError for duplicate email', () async {
      final user = UserEntity(
        name: 'Test Name',
        phone: '1234567890',
        email: 'test@example.com',
        role: UserRole.owner,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await authRepository.createUser(user);

      final duplicateEmailUser = UserEntity(
        name: 'Another Name',
        phone: '0987654321',
        email: 'test@example.com',
        role: UserRole.owner,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await expectLater(
        authRepository.createUser(duplicateEmailUser),
        throwsStateError,
      );
    });

    test('createUser throws StateError for duplicate phone', () async {
      final user = UserEntity(
        name: 'Test Name',
        phone: '1234567890',
        email: 'test@example.com',
        role: UserRole.owner,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await authRepository.createUser(user);

      final duplicatePhoneUser = UserEntity(
        name: 'Another Name',
        phone: '1234567890',
        email: 'another@example.com',
        role: UserRole.owner,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await expectLater(
        authRepository.createUser(duplicatePhoneUser),
        throwsStateError,
      );
    });
  });
}
