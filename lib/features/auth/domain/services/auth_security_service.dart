abstract interface class AuthSecurityService {
  Future<void> savePassword({
    required int userId,
    required String password,
  });

  Future<bool> verifyPassword({
    required int userId,
    required String password,
  });

  Future<void> savePin({
    required int userId,
    required String pin,
  });

  Future<bool> verifyPin({
    required int userId,
    required String pin,
  });

  Future<void> deleteCredentials({
    required int userId,
  });
}
