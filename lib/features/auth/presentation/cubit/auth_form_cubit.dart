import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_form_state.dart';

class AuthFormCubit extends Cubit<AuthFormState> {
  AuthFormCubit() : super(const AuthFormState());

  void togglePasswordVisibility() {
    emit(state.copyWith(obscurePassword: !state.obscurePassword));
  }

  void toggleConfirmPasswordVisibility() {
    emit(state.copyWith(obscureConfirmPassword: !state.obscureConfirmPassword));
  }

  void togglePinVisibility() {
    emit(state.copyWith(obscurePin: !state.obscurePin));
  }

  void selectLoginMode(AuthLoginMode mode) {
    emit(state.copyWith(loginMode: mode));
  }
}
