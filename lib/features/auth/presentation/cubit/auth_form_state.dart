import 'package:equatable/equatable.dart';

class AuthFormState extends Equatable {
  final bool obscurePassword;
  final bool obscureConfirmPassword;

  const AuthFormState({
    this.obscurePassword = true,
    this.obscureConfirmPassword = true,
  });

  AuthFormState copyWith({
    bool? obscurePassword,
    bool? obscureConfirmPassword,
  }) {
    return AuthFormState(
      obscurePassword: obscurePassword ?? this.obscurePassword,
      obscureConfirmPassword:
          obscureConfirmPassword ?? this.obscureConfirmPassword,
    );
  }

  @override
  List<Object?> get props => [obscurePassword, obscureConfirmPassword];
}
