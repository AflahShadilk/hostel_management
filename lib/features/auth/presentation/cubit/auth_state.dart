import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/user_role.dart';

enum AuthStatus {
  initial,
  loading,

  /// No role has ever been selected → show Role Selection page.
  roleSelectionRequired,

  /// A role is stored but the user is not actively logged in → show Login page.
  loginRequired,

  /// A role is stored and the user is logged in → show PIN Lock page.
  pinLockRequired,

  /// PIN setup just completed; waiting for hostel check before home.
  registrationPendingPin,

  /// Fully authenticated and ready to enter the app.
  authenticated,

  failure,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final UserEntity? user;

  /// Populated when the status is [AuthStatus.loginRequired] or
  /// [AuthStatus.pinLockRequired] so the target page knows which role.
  final UserRole? selectedRole;

  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.selectedRole,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    UserRole? selectedRole,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      selectedRole: selectedRole ?? this.selectedRole,
      errorMessage: errorMessage, // intentionally not retained between states
    );
  }

  /// Convenience: retain selectedRole when clearing other fields.
  AuthState copyWithRole(UserRole role) {
    return AuthState(
      status: status,
      user: user,
      selectedRole: role,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, user, selectedRole, errorMessage];
}
