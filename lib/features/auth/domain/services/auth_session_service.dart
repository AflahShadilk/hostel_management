abstract interface class AuthSessionService {
  Future<void> saveSession(int userId);
  Future<int?> getUserId();
  Future<bool> hasSession();
  Future<void> clearSession();
}
