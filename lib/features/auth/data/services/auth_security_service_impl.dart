import '../../../../core/services/secure_storage_service.dart';
import '../../domain/services/auth_security_service.dart';
import 'credential_hash_service.dart';

class AuthSecurityServiceImpl implements AuthSecurityService {
  final SecureStorageService _secureStorage;
  final CredentialHashService _hashService;

  const AuthSecurityServiceImpl(this._secureStorage, this._hashService);

  String _getPasswordHashKey(int userId) => 'auth_user_${userId}_password_hash';
  String _getPasswordSaltKey(int userId) => 'auth_user_${userId}_password_salt';
  String _getPinHashKey(int userId) => 'auth_user_${userId}_pin_hash';
  String _getPinSaltKey(int userId) => 'auth_user_${userId}_pin_salt';

  @override
  Future<void> savePassword({
    required int userId,
    required String password,
  }) async {
    if (password.isEmpty) {
      throw ArgumentError('Password cannot be empty.');
    }

    final salt = _hashService.generateSalt();
    final hash = _hashService.hashCredential(credential: password, salt: salt);

    final hashKey = _getPasswordHashKey(userId);
    final saltKey = _getPasswordSaltKey(userId);

    try {
      await _secureStorage.write(key: saltKey, value: salt);
      await _secureStorage.write(key: hashKey, value: hash);
    } catch (_) {
      // Attempt cleanup on partial write failure
      await _secureStorage.delete(key: saltKey);
      await _secureStorage.delete(key: hashKey);
      rethrow;
    }
  }

  @override
  Future<bool> verifyPassword({
    required int userId,
    required String password,
  }) async {
    if (password.isEmpty) return false;

    final hashKey = _getPasswordHashKey(userId);
    final saltKey = _getPasswordSaltKey(userId);

    final storedHash = await _secureStorage.read(key: hashKey);
    final storedSalt = await _secureStorage.read(key: saltKey);

    if (storedHash == null || storedSalt == null) return false;

    final candidateHash = _hashService.hashCredential(
      credential: password,
      salt: storedSalt,
    );

    return _hashService.verifyHash(
      candidateHash: candidateHash,
      storedHash: storedHash,
    );
  }

  @override
  Future<void> savePin({
    required int userId,
    required String pin,
  }) async {
    if (pin.length != 4 || int.tryParse(pin) == null) {
      throw ArgumentError('PIN must be exactly 4 digits.');
    }

    final salt = _hashService.generateSalt();
    final hash = _hashService.hashCredential(credential: pin, salt: salt);

    final hashKey = _getPinHashKey(userId);
    final saltKey = _getPinSaltKey(userId);

    try {
      await _secureStorage.write(key: saltKey, value: salt);
      await _secureStorage.write(key: hashKey, value: hash);
    } catch (_) {
      // Attempt cleanup on partial write failure
      await _secureStorage.delete(key: saltKey);
      await _secureStorage.delete(key: hashKey);
      rethrow;
    }
  }

  @override
  Future<bool> verifyPin({
    required int userId,
    required String pin,
  }) async {
    if (pin.length != 4 || int.tryParse(pin) == null) {
      return false;
    }

    final hashKey = _getPinHashKey(userId);
    final saltKey = _getPinSaltKey(userId);

    final storedHash = await _secureStorage.read(key: hashKey);
    final storedSalt = await _secureStorage.read(key: saltKey);

    if (storedHash == null || storedSalt == null) return false;

    final candidateHash = _hashService.hashCredential(
      credential: pin,
      salt: storedSalt,
    );

    return _hashService.verifyHash(
      candidateHash: candidateHash,
      storedHash: storedHash,
    );
  }

  @override
  Future<void> deleteCredentials({required int userId}) async {
    await _secureStorage.delete(key: _getPasswordHashKey(userId));
    await _secureStorage.delete(key: _getPasswordSaltKey(userId));
    await _secureStorage.delete(key: _getPinHashKey(userId));
    await _secureStorage.delete(key: _getPinSaltKey(userId));
  }
}
