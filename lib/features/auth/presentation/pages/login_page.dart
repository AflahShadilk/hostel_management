import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/user_role.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/presentation/authenticated_destination_resolver.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../cubit/auth_form_cubit.dart';
import '../cubit/auth_form_state.dart';

class LoginPage extends StatefulWidget {
  final UserRole role;

  const LoginPage({
    super.key,
    required this.role,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pinController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _onModeChanged(BuildContext context, AuthLoginMode mode) {
    context.read<AuthFormCubit>().selectLoginMode(mode);
    if (mode == AuthLoginMode.password) {
      _pinController.clear();
    } else {
      _passwordController.clear();
    }
  }

  void _submit(BuildContext context) {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() ?? false) {
      final loginMode = context.read<AuthFormCubit>().state.loginMode;

      if (loginMode == AuthLoginMode.password) {
        context.read<AuthCubit>().loginWithPassword(
              role: widget.role,
              email: _emailController.text,
              password: _passwordController.text,
            );
      } else {
        context.read<AuthCubit>().loginWithPin(
              role: widget.role,
              email: _emailController.text,
              pin: _pinController.text,
            );
      }
    }
  }

  String get _appBarTitle {
    return widget.role == UserRole.owner ? 'Owner Login' : 'Manager Login';
  }

  String get _heading {
    return widget.role == UserRole.owner
        ? 'Welcome back, Owner'
        : 'Welcome back, Manager';
  }

  String get _supportingText {
    return widget.role == UserRole.owner
        ? 'Sign in to manage your hostel.'
        : 'Sign in to continue managing hostel operations.';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthFormCubit(),
      child: BlocConsumer<AuthCubit, AuthState>(
        listenWhen: (previous, current) =>
            previous.status != current.status ||
            previous.errorMessage != current.errorMessage,
        listener: (context, state) {
          if (state.status == AuthStatus.failure &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
              ),
            );
          }
          // AuthStatus.authenticated is handled by the builder below via
          // AuthenticatedDestinationResolver to avoid a Home page flash.
        },
        builder: (context, authState) {
          // When authenticated, overlay the resolver to handle hostel check.
          if (authState.status == AuthStatus.authenticated &&
              authState.user != null) {
            return AuthenticatedDestinationResolver(
              user: authState.user!,
              onNavigate: (routeName) =>
                  context.pushReplacementNamed(routeName),
            );
          }

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Text(_appBarTitle),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.goNamed(AppRoutes.roleSelectionName);
                  }
                },
              ),
            ),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Builder(builder: (context) {
                      return Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Icon(
                              widget.role == UserRole.owner
                                  ? Icons.business_center_rounded
                                  : Icons.admin_panel_settings_rounded,
                              size: 48,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              _heading,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              _supportingText,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            // Mode Selector
                            BlocSelector<AuthFormCubit, AuthFormState,
                                AuthLoginMode>(
                              selector: (state) => state.loginMode,
                              builder: (context, loginMode) {
                                return SegmentedButton<AuthLoginMode>(
                                  segments: const [
                                    ButtonSegment<AuthLoginMode>(
                                      value: AuthLoginMode.password,
                                      label: Text('Password'),
                                      icon: Icon(Icons.password_rounded),
                                    ),
                                    ButtonSegment<AuthLoginMode>(
                                      value: AuthLoginMode.pin,
                                      label: Text('PIN'),
                                      icon: Icon(Icons.pin_rounded),
                                    ),
                                  ],
                                  selected: {loginMode},
                                  onSelectionChanged:
                                      (Set<AuthLoginMode> newSelection) {
                                    _onModeChanged(
                                        context, newSelection.first);
                                  },
                                );
                              },
                            ),

                            const SizedBox(height: AppSpacing.xl),

                            // Email Field (Shared)
                            AppTextField(
                              controller: _emailController,
                              label: 'Email Address',
                              prefixIcon: const Icon(Icons.email_outlined),
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your email address';
                                }
                                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                    .hasMatch(value.trim())) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: AppSpacing.md),

                            // Password or PIN Field
                            BlocSelector<AuthFormCubit, AuthFormState,
                                AuthLoginMode>(
                              selector: (state) => state.loginMode,
                              builder: (context, loginMode) {
                                if (loginMode == AuthLoginMode.password) {
                                  return BlocSelector<AuthFormCubit,
                                      AuthFormState, bool>(
                                    selector: (state) => state.obscurePassword,
                                    builder: (context, obscurePassword) {
                                      return AppTextField(
                                        controller: _passwordController,
                                        label: 'Password',
                                        prefixIcon: const Icon(
                                            Icons.lock_outline_rounded),
                                        obscureText: obscurePassword,
                                        textInputAction: TextInputAction.done,
                                        autofillHints: const [
                                          AutofillHints.password
                                        ],
                                        onFieldSubmitted: (_) =>
                                            _submit(context),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            obscurePassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            color: AppColors.textSecondary,
                                          ),
                                          onPressed: () => context
                                              .read<AuthFormCubit>()
                                              .togglePasswordVisibility(),
                                          tooltip: obscurePassword
                                              ? 'Show password'
                                              : 'Hide password',
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.isEmpty) {
                                            return 'Please enter a password';
                                          }
                                          return null;
                                        },
                                      );
                                    },
                                  );
                                } else {
                                  return BlocSelector<AuthFormCubit,
                                      AuthFormState, bool>(
                                    selector: (state) => state.obscurePin,
                                    builder: (context, obscurePin) {
                                      return AppTextField(
                                        controller: _pinController,
                                        label: '4-digit PIN',
                                        prefixIcon:
                                            const Icon(Icons.dialpad_rounded),
                                        obscureText: obscurePin,
                                        keyboardType: TextInputType.number,
                                        textInputAction: TextInputAction.done,
                                        maxLength: 4,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          LengthLimitingTextInputFormatter(4),
                                        ],
                                        onFieldSubmitted: (_) =>
                                            _submit(context),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            obscurePin
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            color: AppColors.textSecondary,
                                          ),
                                          onPressed: () => context
                                              .read<AuthFormCubit>()
                                              .togglePinVisibility(),
                                          tooltip: obscurePin
                                              ? 'Show PIN'
                                              : 'Hide PIN',
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.isEmpty) {
                                            return 'Please enter your PIN';
                                          }
                                          if (value.length != 4) {
                                            return 'PIN must be exactly 4 digits';
                                          }
                                          return null;
                                        },
                                      );
                                    },
                                  );
                                }
                              },
                            ),

                            const SizedBox(height: AppSpacing.xl),

                            // Sign In Button
                            BlocSelector<AuthCubit, AuthState, bool>(
                              selector: (state) =>
                                  state.status == AuthStatus.loading,
                              builder: (context, isLoading) {
                                return AppButton(
                                  label: 'Sign In',
                                  isLoading: isLoading,
                                  isFullWidth: true,
                                  onPressed: isLoading
                                      ? null
                                      : () => _submit(context),
                                );
                              },
                            ),

                            // Optional Sign Up section for Owner
                            if (widget.role == UserRole.owner) ...[
                              const SizedBox(height: AppSpacing.lg),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Don\'t have an account?',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      context.pushReplacementNamed(
                                          AppRoutes.ownerSignUpName);
                                    },
                                    child: const Text('Sign Up'),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
