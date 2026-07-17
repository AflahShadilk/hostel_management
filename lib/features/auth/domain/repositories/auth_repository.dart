import '../entities/user_entity.dart';
import '../entities/user_role.dart';

abstract interface class AuthRepository {
  Future<UserEntity> createUser(UserEntity user);
  Future<UserEntity?> getUserByEmail(String email);
  Future<UserEntity?> getUserById(int id);
  Future<List<UserEntity>> getUsersByRole(UserRole role);
  Future<bool> emailExists(String email);
  Future<bool> phoneExists(String phone);
}
