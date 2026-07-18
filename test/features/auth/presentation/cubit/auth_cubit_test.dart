import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_management/features/auth/domain/entities/user_entity.dart';
import 'package:hostel_management/features/auth/domain/entities/user_role.dart';
import 'package:hostel_management/features/auth/domain/repositories/auth_repository.dart';
import 'package:hostel_management/features/auth/domain/services/auth_security_service.dart';
import 'package:hostel_management/features/auth/domain/services/auth_session_service.dart';
import 'package:hostel_management/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:hostel_management/features/auth/presentation/cubit/auth_state.dart';

// --- Fakes ---

class FakeAuthRepository implements AuthRepository {
  bool emailExistsResult = false;
  bool phoneExistsResult = false;
  UserEntity? userToReturn;
  UserEntity? createdUser;
  bool deleteUserCalled = false;
  int idCounter = 1;

  @override
  Future<UserEntity> createUser(UserEntity user) async {
    createdUser = UserEntity(
      id: idCounter++,
      name: user.name,
      phone: user.phone,
      email: user.email,
      role: user.role,
      isActive: user.isActive,
      createdAt: user.createdAt,
    );
    return createdUser!;
  }

  @override
  Future<void> deleteUser(int id) async {
    deleteUserCalled = true;
  }

  @override
  Future<bool> emailExists(String email) async => emailExistsResult;

  @override
  Future<UserEntity?> getUserByEmail(String email) async => userToReturn;

  @override
  Future<UserEntity?> getUserById(int id) async => userToReturn;

  @override
  Future<List<UserEntity>> getUsersByRole(UserRole role) async => [];

  @override
  Future<bool> phoneExists(String phone) async => phoneExistsResult;
}

class FakeAuthSecurityService implements AuthSecurityService {
  bool savePasswordFails = false;
  bool savePasswordCalled = false;
  bool savePinFails = false;
  bool savePinCalled = false;
  bool verifyPasswordResult = true;
  bool verifyPinResult = true;

  @override
  Future<void> deleteCredentials({required int userId}) async {}

  @override
  Future<void> savePassword(
      {required int userId, required String password}) async {
    savePasswordCalled = true;
    if (savePasswordFails) throw Exception('Storage error');
  }

  @override
  Future<void> savePin({required int userId, required String pin}) async {
    savePinCalled = true;
    if (savePinFails) throw Exception('Storage error');
  }

  @override
  Future<bool> verifyPassword(
          {required int userId, required String password}) async =>
      verifyPasswordResult;

  @override
  Future<bool> verifyPin({required int userId, required String pin}) async =>
      verifyPinResult;
}

class FakeAuthSessionService implements AuthSessionService {
  int? savedUserId;
  int? userIdToReturn;
  bool clearSessionCalled = false;

  @override
  Future<void> clearSession() async {
    clearSessionCalled = true;
    savedUserId = null;
  }

  @override
  Future<int?> getUserId() async => userIdToReturn;

  @override
  Future<bool> hasSession() async => userIdToReturn != null;

  @override
  Future<void> saveSession(int userId) async {
    savedUserId = userId;
  }
}

// --- Tests ---

void main() {
  late FakeAuthRepository authRepository;
  late FakeAuthSecurityService authSecurityService;
  late FakeAuthSessionService authSessionService;
  late AuthCubit authCubit;

  setUp(() {
    authRepository = FakeAuthRepository();
    authSecurityService = FakeAuthSecurityService();
    authSessionService = FakeAuthSessionService();

    authCubit = AuthCubit(
      authRepository,
      authSecurityService,
      authSessionService,
    );
  });

  tearDown(() {
    authCubit.close();
  });

  group('AuthCubit Owner Registration', () {
    test('Rejects blank name', () async {
      await authCubit.registerOwner(name: '   ', phone: '1234567890', email: 't@t.com', password: 'password123');
      expect(authCubit.state.status, AuthStatus.failure);
      expect(authCubit.state.errorMessage, 'Please enter your name.');
    });

    test('Rejects blank phone', () async {
      await authCubit.registerOwner(name: 'Owner', phone: '', email: 't@t.com', password: 'password123');
      expect(authCubit.state.status, AuthStatus.failure);
      expect(authCubit.state.errorMessage, 'Please enter your phone number.');
    });

    test('Rejects invalid email', () async {
      await authCubit.registerOwner(name: 'Owner', phone: '1234567890', email: 'invalid', password: 'password123');
      expect(authCubit.state.status, AuthStatus.failure);
      expect(authCubit.state.errorMessage, 'Please enter a valid email address.');
    });

    test('Rejects short password', () async {
      await authCubit.registerOwner(name: 'Owner', phone: '1234567890', email: 't@example.com', password: 'short');
      expect(authCubit.state.status, AuthStatus.failure);
      expect(authCubit.state.errorMessage, 'Password must be at least 8 characters.');
    });

    test('Rejects duplicate email', () async {
      authRepository.emailExistsResult = true;
      await authCubit.registerOwner(name: 'Owner', phone: '1234567890', email: 't@example.com', password: 'password123');
      expect(authCubit.state.status, AuthStatus.failure);
      expect(authCubit.state.errorMessage, 'This email address is already registered.');
    });

    test('Rejects duplicate phone', () async {
      authRepository.phoneExistsResult = true;
      await authCubit.registerOwner(name: 'Owner', phone: '1234567890', email: 't@example.com', password: 'password123');
      expect(authCubit.state.status, AuthStatus.failure);
      expect(authCubit.state.errorMessage, 'This phone number is already registered.');
    });

    test('Successful registration emits registrationPendingPin', () async {
      await authCubit.registerOwner(
        name: 'Test Owner',
        phone: '1234567890',
        email: 'test@example.com',
        password: 'password123',
      );

      expect(authCubit.state.status, AuthStatus.registrationPendingPin);
      expect(authCubit.state.user, isNotNull);

      expect(authSecurityService.savePasswordCalled, isTrue);
      expect(authSessionService.savedUserId, isNull); // Session not saved yet
    });

    test('Registration failure during password save triggers rollback',
        () async {
      authSecurityService.savePasswordFails = true;

      await authCubit.registerOwner(
        name: 'Test Owner',
        phone: '1234567890',
        email: 'test@example.com',
        password: 'password123',
      );

      expect(authCubit.state.status, AuthStatus.failure);
      expect(authRepository.deleteUserCalled, isTrue);
    });
  });

  group('AuthCubit PIN Setup', () {
    test('Successful PIN setup saves session and emits authenticated',
        () async {
      // First, simulate pending state
      await authCubit.registerOwner(
        name: 'Test Owner',
        phone: '1234567890',
        email: 'test@example.com',
        password: 'password123',
      );

      await authCubit.setupPin('1234');

      expect(authCubit.state.status, AuthStatus.authenticated);
      expect(authSecurityService.savePinCalled, isTrue);
      expect(authSessionService.savedUserId, authRepository.createdUser!.id);
    });

    test('PIN setup failure retains user and emits failure', () async {
      // Register owner to reach registrationPendingPin
      await authCubit.registerOwner(
        name: 'Test Owner',
        phone: '1234567890',
        email: 'test@example.com',
        password: 'password123',
      );
      expect(authCubit.state.status, AuthStatus.registrationPendingPin);
      final pendingUser = authCubit.state.user;

      // Make PIN save fail
      authSecurityService.savePinFails = true;
      await authCubit.setupPin('1234');

      expect(authCubit.state.status, AuthStatus.failure);
      // Critically, the user must still be retained for retry
      expect(authCubit.state.user, pendingUser);
      expect(authCubit.state.errorMessage,
          'Unable to set up PIN. Please try again.');
    });

    test('PIN setup can be retried after failure', () async {
      // Register owner to reach registrationPendingPin
      await authCubit.registerOwner(
        name: 'Test Owner',
        phone: '1234567890',
        email: 'test@example.com',
        password: 'password123',
      );

      // First attempt fails
      authSecurityService.savePinFails = true;
      await authCubit.setupPin('1234');
      expect(authCubit.state.status, AuthStatus.failure);
      expect(authCubit.state.user, isNotNull);

      // Second attempt succeeds
      authSecurityService.savePinFails = false;
      authSecurityService.savePinCalled = false;
      await authCubit.setupPin('1234');

      expect(authCubit.state.status, AuthStatus.authenticated);
      expect(authSecurityService.savePinCalled, isTrue);
    });

    test('setupPin is a no-op when status is unrelated failure with no user',
        () async {
      // State: failure with no user (e.g. from a login failure)
      await authCubit.loginWithPassword(
        role: UserRole.owner,
        email: 'none@example.com',
        password: 'wrong',
      );
      expect(authCubit.state.status, AuthStatus.failure);
      expect(authCubit.state.user, isNull);

      // setupPin must not proceed
      authSecurityService.savePinCalled = false;
      await authCubit.setupPin('1234');

      expect(authSecurityService.savePinCalled, isFalse);
    });
  });

  group('AuthCubit Password Login', () {
    test('Invalid password emits generic failure', () async {
      authRepository.userToReturn = UserEntity(
        id: 1,
        name: 'Owner',
        phone: '123',
        email: 'test@example.com',
        role: UserRole.owner,
        isActive: true,
        createdAt: DateTime.now(),
      );
      authSecurityService.verifyPasswordResult = false; // Invalid password

      await authCubit.loginWithPassword(
        role: UserRole.owner,
        email: 'test@example.com',
        password: 'wrongpassword',
      );

      expect(authCubit.state.status, AuthStatus.failure);
      expect(authCubit.state.errorMessage, 'Invalid email or password.');
      expect(authSessionService.savedUserId, isNull);
    });
  });

  group('AuthCubit Session Restoration', () {
    test('Missing session emits unauthenticated', () async {
      authSessionService.userIdToReturn = null;

      await authCubit.checkAuthStatus();

      expect(authCubit.state.status, AuthStatus.unauthenticated);
    });
  });

  group('AuthCubit Logout', () {
    test('Logout clears session and emits unauthenticated', () async {
      await authCubit.logout();

      expect(authCubit.state.status, AuthStatus.unauthenticated);
      expect(authSessionService.clearSessionCalled, isTrue);
    });
  });
}
