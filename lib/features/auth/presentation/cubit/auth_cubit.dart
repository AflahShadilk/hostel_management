import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/services/auth_security_service.dart';
import '../../domain/services/auth_session_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  final AuthSecurityService _authSecurityService;
  final AuthSessionService _authSessionService;

  AuthCubit(
    this._authRepository,
    this._authSecurityService,
    this._authSessionService,
  ) : super(const AuthState());

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email);
  }

  // ── Registration ─────────────────────────────────────────────────────────────

  Future<void> registerOwner({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    if (state.status == AuthStatus.loading) return;

    emit(state.copyWith(status: AuthStatus.loading));

    final normalizedName = name.trim();
    final normalizedPhone = phone.trim();
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedName.isEmpty) {
      emit(state.copyWith(
          status: AuthStatus.failure, errorMessage: 'Please enter your name.'));
      return;
    }
    if (normalizedPhone.isEmpty) {
      emit(state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Please enter your phone number.'));
      return;
    }
    if (normalizedEmail.isEmpty || !_isValidEmail(normalizedEmail)) {
      emit(state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Please enter a valid email address.'));
      return;
    }
    if (password.length < 8) {
      emit(state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Password must be at least 8 characters.'));
      return;
    }

    try {
      final emailExists = await _authRepository.emailExists(normalizedEmail);
      if (emailExists) {
        emit(state.copyWith(
            status: AuthStatus.failure,
            errorMessage: 'This email address is already registered.'));
        return;
      }

      final phoneExists = await _authRepository.phoneExists(normalizedPhone);
      if (phoneExists) {
        emit(state.copyWith(
            status: AuthStatus.failure,
            errorMessage: 'This phone number is already registered.'));
        return;
      }

      final newUser = UserEntity(
        name: normalizedName,
        phone: normalizedPhone,
        email: normalizedEmail,
        role: UserRole.owner,
        isActive: true,
        createdAt: DateTime.now(),
      );

      final persistedUser = await _authRepository.createUser(newUser);
      final userId = persistedUser.id;

      if (userId == null) {
        emit(state.copyWith(
            status: AuthStatus.failure,
            errorMessage:
                'Unable to complete registration. Please try again.'));
        return;
      }

      try {
        await _authSecurityService.savePassword(
            userId: userId, password: password);
      } catch (e) {
        // Rollback safety
        await _authRepository.deleteUser(userId);
        emit(state.copyWith(
            status: AuthStatus.failure,
            errorMessage:
                'Unable to complete registration. Please try again.'));
        return;
      }

      // Persist the role so the next launch knows Owner was selected
      await _authSessionService.saveRole(UserRole.owner);

      emit(state.copyWith(
          status: AuthStatus.registrationPendingPin, user: persistedUser));
    } on StateError catch (e) {
      emit(state.copyWith(
          status: AuthStatus.failure, errorMessage: e.message));
    } catch (e) {
      emit(state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Something went wrong. Please try again.'));
    }
  }

  // ── PIN Setup (after registration) ───────────────────────────────────────────

  Future<void> setupPin(String pin) async {
    if (state.status == AuthStatus.loading) return;

    final canRetry = state.status == AuthStatus.failure && state.user != null;
    if ((state.status != AuthStatus.registrationPendingPin && !canRetry) ||
        state.user == null) {
      return;
    }

    final currentUser = state.user!;
    final userId = currentUser.id;

    if (userId == null) return;

    emit(state.copyWith(status: AuthStatus.loading));

    if (pin.length != 4 || int.tryParse(pin) == null) {
      emit(state.copyWith(
          status: AuthStatus.failure,
          user: currentUser,
          errorMessage: 'PIN must be exactly 4 digits.'));
      return;
    }

    try {
      await _authSecurityService.savePin(userId: userId, pin: pin);
      await _authSessionService.markLoggedIn(userId);
      emit(state.copyWith(status: AuthStatus.authenticated, user: currentUser));
    } catch (_) {
      emit(state.copyWith(
          status: AuthStatus.failure,
          user: currentUser,
          errorMessage: 'Unable to set up PIN. Please try again.'));
    }
  }

  // ── Role Selection (first-time or after logout re-select) ────────────────────

  /// Called when the user taps a role card on the Role Selection page.
  /// Persists the role and emits [AuthStatus.loginRequired] so Splash/listener
  /// navigates to the correct Login page.
  Future<void> selectRole(UserRole role) async {
    if (state.status == AuthStatus.loading) return;

    emit(state.copyWith(status: AuthStatus.loading));

    try {
      await _authSessionService.saveRole(role);
      emit(AuthState(
        status: AuthStatus.loginRequired,
        selectedRole: role,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'Unable to save role selection. Please try again.',
      ));
    }
  }

  // ── Password Login ────────────────────────────────────────────────────────────

  Future<void> loginWithPassword({
    required UserRole role,
    required String email,
    required String password,
  }) async {
    if (state.status == AuthStatus.loading) return;

    emit(state.copyWith(status: AuthStatus.loading));

    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedEmail.isEmpty || password.isEmpty) {
      emit(state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Invalid email or password.'));
      return;
    }

    try {
      final user = await _authRepository.getUserByEmail(normalizedEmail);
      if (user == null || user.role != role) {
        emit(state.copyWith(
            status: AuthStatus.failure,
            errorMessage: 'Invalid email or password.'));
        return;
      }

      if (!user.isActive) {
        emit(state.copyWith(
            status: AuthStatus.failure,
            errorMessage: 'Your account is inactive.'));
        return;
      }

      final valid = await _authSecurityService.verifyPassword(
          userId: user.id!, password: password);
      if (!valid) {
        emit(state.copyWith(
            status: AuthStatus.failure,
            errorMessage: 'Invalid email or password.'));
        return;
      }

      // Persist both role and login flag
      await _authSessionService.saveRole(role);
      await _authSessionService.markLoggedIn(user.id!);

      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch (_) {
      emit(state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Unable to sign in. Please try again.'));
    }
  }

  // ── PIN Login (email + PIN — legacy login page mode) ────────────────────────

  Future<void> loginWithPin({
    required UserRole role,
    required String email,
    required String pin,
  }) async {
    if (state.status == AuthStatus.loading) return;

    emit(state.copyWith(status: AuthStatus.loading));

    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedEmail.isEmpty ||
        pin.length != 4 ||
        int.tryParse(pin) == null) {
      emit(state.copyWith(
          status: AuthStatus.failure, errorMessage: 'Invalid email or PIN.'));
      return;
    }

    try {
      final user = await _authRepository.getUserByEmail(normalizedEmail);
      if (user == null || user.role != role) {
        emit(state.copyWith(
            status: AuthStatus.failure, errorMessage: 'Invalid email or PIN.'));
        return;
      }

      if (!user.isActive) {
        emit(state.copyWith(
            status: AuthStatus.failure,
            errorMessage: 'Your account is inactive.'));
        return;
      }

      final valid =
          await _authSecurityService.verifyPin(userId: user.id!, pin: pin);
      if (!valid) {
        emit(state.copyWith(
            status: AuthStatus.failure, errorMessage: 'Invalid email or PIN.'));
        return;
      }

      // Persist both role and login flag
      await _authSessionService.saveRole(role);
      await _authSessionService.markLoggedIn(user.id!);

      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch (_) {
      emit(state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Unable to sign in. Please try again.'));
    }
  }

  // ── PIN Unlock (PIN Lock screen — no email needed) ────────────────────────────

  /// Called from the PIN Lock page. Loads the user from the stored session
  /// and verifies only the PIN — no email input required.
  Future<void> unlockWithPin(String pin) async {
    if (state.status == AuthStatus.loading) return;

    emit(state.copyWith(status: AuthStatus.loading));

    if (pin.length != 4 || int.tryParse(pin) == null) {
      emit(state.copyWith(
        status: AuthStatus.pinLockRequired,
        user: state.user,
        selectedRole: state.selectedRole,
        errorMessage: 'PIN must be exactly 4 digits.',
      ));
      return;
    }

    try {
      final userId = await _authSessionService.getUserId();
      if (userId == null) {
        // Session is gone — send back to login
        final role = await _authSessionService.getRole();
        emit(AuthState(
          status: AuthStatus.loginRequired,
          selectedRole: role,
          errorMessage: 'Session expired. Please sign in again.',
        ));
        return;
      }

      final user = await _authRepository.getUserById(userId);
      if (user == null || !user.isActive) {
        await _authSessionService.clearAll();
        emit(const AuthState(
          status: AuthStatus.roleSelectionRequired,
          errorMessage: 'Account not found. Please sign in again.',
        ));
        return;
      }

      final valid =
          await _authSecurityService.verifyPin(userId: userId, pin: pin);
      if (!valid) {
        emit(state.copyWith(
          status: AuthStatus.pinLockRequired,
          user: user,
          selectedRole: user.role,
          errorMessage: 'Incorrect PIN. Please try again.',
        ));
        return;
      }

      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch (_) {
      emit(state.copyWith(
          status: AuthStatus.pinLockRequired,
          user: state.user,
          selectedRole: state.selectedRole,
          errorMessage: 'Unable to verify PIN. Please try again.'));
    }
  }

  // ── Forgot PIN — clear login flag, return to Login ───────────────────────────

  /// Clears the active login session so the next navigation goes to Login.
  /// Keeps the role so the correct Login page is shown.
  Future<void> forgotPin() async {
    if (state.status == AuthStatus.loading) return;

    emit(state.copyWith(status: AuthStatus.loading));

    try {
      await _authSessionService.clearLoginSession();
      final role = state.selectedRole ?? await _authSessionService.getRole();
      emit(AuthState(
        status: AuthStatus.loginRequired,
        selectedRole: role,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'Unable to proceed. Please try again.',
      ));
    }
  }

  // ── Startup Auth Check ────────────────────────────────────────────────────────

  Future<void> checkAuthStatus() async {
    if (state.status == AuthStatus.loading) return;

    emit(state.copyWith(status: AuthStatus.loading));

    try {
      // 1. Is a role stored?
      final storedRole = await _authSessionService.getRole();
      if (storedRole == null) {
        emit(const AuthState(status: AuthStatus.roleSelectionRequired));
        return;
      }

      // 2. Is the user actively logged in?
      final loggedIn = await _authSessionService.isLoggedIn();
      if (!loggedIn) {
        emit(AuthState(
          status: AuthStatus.loginRequired,
          selectedRole: storedRole,
        ));
        return;
      }

      // 3. Load the user entity for the PIN Lock screen.
      final userId = await _authSessionService.getUserId();
      if (userId == null) {
        // Stale login flag — treat as logged out
        await _authSessionService.clearLoginSession();
        emit(AuthState(
          status: AuthStatus.loginRequired,
          selectedRole: storedRole,
        ));
        return;
      }

      final user = await _authRepository.getUserById(userId);
      if (user == null || !user.isActive) {
        await _authSessionService.clearAll();
        emit(const AuthState(status: AuthStatus.roleSelectionRequired));
        return;
      }

      emit(AuthState(
        status: AuthStatus.pinLockRequired,
        user: user,
        selectedRole: storedRole,
      ));
    } catch (_) {
      // On any failure, fall back gracefully without crashing
      emit(const AuthState(status: AuthStatus.roleSelectionRequired));
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    if (state.status == AuthStatus.loading) return;

    emit(state.copyWith(status: AuthStatus.loading));

    try {
      await _authSessionService.clearAll();
      emit(const AuthState(status: AuthStatus.roleSelectionRequired));
    } catch (_) {
      emit(state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Unable to log out. Please try again.'));
    }
  }
}
