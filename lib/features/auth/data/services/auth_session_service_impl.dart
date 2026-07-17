import '../../../../core/services/secure_storage_service.dart';
import '../../domain/services/auth_session_service.dart';

class AuthSessionServiceImpl implements AuthSessionService {
  final SecureStorageService _secureStorage;
  static const String _sessionKey = 'auth_session_user_id';

  const AuthSessionServiceImpl(this._secureStorage);

  @override
  Future<void> saveSession(int userId) async {
    await _secureStorage.write(key: _sessionKey, value: userId.toString());
  }

  @override
  Future<int?> getUserId() async {
    final value = await _secureStorage.read(key: _sessionKey);
    if (value == null) return null;

    // Treat a corrupted/non-integer string as a missing session
    return int.tryParse(value);
  }

  @override
  Future<bool> hasSession() async {
    return await getUserId() != null;
  }

  @override
  Future<void> clearSession() async {
    await _secureStorage.delete(key: _sessionKey);
  }
}
