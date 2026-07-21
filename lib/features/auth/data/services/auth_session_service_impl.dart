import '../../../../core/services/secure_storage_service.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/services/auth_session_service.dart';

class AuthSessionServiceImpl implements AuthSessionService {
  final SecureStorageService _secureStorage;

  // ── Storage keys ─────────────────────────────────────────────────────────────
  static const String _userIdKey = 'auth_session_user_id';
  static const String _selectedRoleKey = 'auth_selected_role';
  static const String _isLoggedInKey = 'auth_is_logged_in';

  const AuthSessionServiceImpl(this._secureStorage);

  // ── Legacy session (userId only) ─────────────────────────────────────────────
  @override
  Future<void> saveSession(int userId) async {
    await _secureStorage.write(key: _userIdKey, value: userId.toString());
  }

  @override
  Future<int?> getUserId() async {
    final value = await _secureStorage.read(key: _userIdKey);
    if (value == null) return null;
    return int.tryParse(value);
  }

  @override
  Future<bool> hasSession() async {
    return await getUserId() != null;
  }

  @override
  Future<void> clearSession() async {
    await _secureStorage.delete(key: _userIdKey);
  }

  // ── Role persistence ─────────────────────────────────────────────────────────
  @override
  Future<void> saveRole(UserRole role) async {
    await _secureStorage.write(
      key: _selectedRoleKey,
      value: role.databaseValue,
    );
  }

  @override
  Future<UserRole?> getRole() async {
    final value = await _secureStorage.read(key: _selectedRoleKey);
    if (value == null) return null;
    return UserRole.fromDatabaseValue(value);
  }

  @override
  Future<void> clearRole() async {
    await _secureStorage.delete(key: _selectedRoleKey);
  }

  // ── Login-session flag ────────────────────────────────────────────────────────
  @override
  Future<void> markLoggedIn(int userId) async {
    await _secureStorage.write(key: _userIdKey, value: userId.toString());
    await _secureStorage.write(key: _isLoggedInKey, value: 'true');
  }

  @override
  Future<bool> isLoggedIn() async {
    final value = await _secureStorage.read(key: _isLoggedInKey);
    return value == 'true';
  }

  @override
  Future<void> clearLoginSession() async {
    await _secureStorage.delete(key: _isLoggedInKey);
    // Keep the userId so we still know who to show on the Login page
    // Keep the role so we navigate directly to the correct Login page
  }

  // ── Full logout ───────────────────────────────────────────────────────────────
  @override
  Future<void> clearAll() async {
    await _secureStorage.delete(key: _userIdKey);
    await _secureStorage.delete(key: _selectedRoleKey);
    await _secureStorage.delete(key: _isLoggedInKey);
  }
}
