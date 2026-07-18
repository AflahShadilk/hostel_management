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
      await _authSessionService.saveSession(userId);
      emit(state.copyWith(status: AuthStatus.authenticated, user: currentUser));
    } catch (_) {
      emit(state.copyWith(
          status: AuthStatus.failure,
          user: currentUser,
          errorMessage: 'Unable to set up PIN. Please try again.'));
    }
  }

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

      await _authSessionService.saveSession(user.id!);
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch (_) {
      emit(state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Unable to sign in. Please try again.'));
    }
  }

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

      await _authSessionService.saveSession(user.id!);
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch (_) {
      emit(state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Unable to sign in. Please try again.'));
    }
  }

  Future<void> checkAuthStatus() async {
    if (state.status == AuthStatus.loading) return;

    emit(state.copyWith(status: AuthStatus.loading));

    try {
      final userId = await _authSessionService.getUserId();
      if (userId == null) {
        emit(state.copyWith(status: AuthStatus.unauthenticated));
        return;
      }

      final user = await _authRepository.getUserById(userId);
      if (user == null || !user.isActive) {
        await _authSessionService.clearSession();
        emit(state.copyWith(status: AuthStatus.unauthenticated));
        return;
      }

      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch (_) {
      // In case of error (e.g. database failure), remain unauthenticated
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> logout() async {
    if (state.status == AuthStatus.loading) return;

    emit(state.copyWith(status: AuthStatus.loading));

    try {
      await _authSessionService.clearSession();
      emit(const AuthState(status: AuthStatus.unauthenticated));
    } catch (_) {
      emit(state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Unable to log out. Please try again.'));
    }
  }
}
