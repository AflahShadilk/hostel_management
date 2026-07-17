import '../../../../core/database/app_database.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AppDatabase _appDatabase;

  const AuthRepositoryImpl(this._appDatabase);

  @override
  Future<UserEntity> createUser(UserEntity user) async {
    final db = await _appDatabase.database;

    // Normalise inputs at the persistence boundary
    final normalisedUser = UserEntity(
      id: user.id,
      name: user.name.trim(),
      phone: user.phone.trim(),
      email: user.email.trim().toLowerCase(),
      role: user.role,
      isActive: user.isActive,
      createdAt: user.createdAt,
    );

    final id = await db.insert(
      'users',
      UserModel.toMap(normalisedUser),
    );

    return UserEntity(
      id: id,
      name: normalisedUser.name,
      phone: normalisedUser.phone,
      email: normalisedUser.email,
      role: normalisedUser.role,
      isActive: normalisedUser.isActive,
      createdAt: normalisedUser.createdAt,
    );
  }

  @override
  Future<UserEntity?> getUserByEmail(String email) async {
    final db = await _appDatabase.database;
    final results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return UserModel.fromMap(results.first);
  }

  @override
  Future<UserEntity?> getUserById(int id) async {
    final db = await _appDatabase.database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return UserModel.fromMap(results.first);
  }

  @override
  Future<List<UserEntity>> getUsersByRole(UserRole role) async {
    final db = await _appDatabase.database;
    final results = await db.query(
      'users',
      where: 'role = ?',
      whereArgs: [role.databaseValue],
    );

    return results.map((map) => UserModel.fromMap(map)).toList();
  }

  @override
  Future<bool> emailExists(String email) async {
    final db = await _appDatabase.database;
    final results = await db.query(
      'users',
      columns: ['1'],
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    return results.isNotEmpty;
  }

  @override
  Future<bool> phoneExists(String phone) async {
    final db = await _appDatabase.database;
    final results = await db.query(
      'users',
      columns: ['1'],
      where: 'phone = ?',
      whereArgs: [phone.trim()],
      limit: 1,
    );
    return results.isNotEmpty;
  }
}
