import 'package:equatable/equatable.dart';

enum AuthLoginMode { password, pin }

class AuthFormState extends Equatable {
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final bool obscurePin;
  final bool obscureConfirmPin;
  final AuthLoginMode loginMode;

  const AuthFormState({
    this.obscurePassword = true,
    this.obscureConfirmPassword = true,
    this.obscurePin = true,
    this.obscureConfirmPin = true,
    this.loginMode = AuthLoginMode.password,
  });

  AuthFormState copyWith({
    bool? obscurePassword,
    bool? obscureConfirmPassword,
    bool? obscurePin,
    bool? obscureConfirmPin,
    AuthLoginMode? loginMode,
  }) {
    return AuthFormState(
      obscurePassword: obscurePassword ?? this.obscurePassword,
      obscureConfirmPassword:
          obscureConfirmPassword ?? this.obscureConfirmPassword,
      obscurePin: obscurePin ?? this.obscurePin,
      obscureConfirmPin: obscureConfirmPin ?? this.obscureConfirmPin,
      loginMode: loginMode ?? this.loginMode,
    );
  }

  @override
  List<Object?> get props => [
        obscurePassword,
        obscureConfirmPassword,
        obscurePin,
        obscureConfirmPin,
        loginMode,
      ];
}
