import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../cubit/auth_form_cubit.dart';
import '../cubit/auth_form_state.dart';

class PinSetupPage extends StatefulWidget {
  const PinSetupPage({super.key});

  @override
  State<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends State<PinSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().setupPin(_pinController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthFormCubit(),
      child: BlocListener<AuthCubit, AuthState>(
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
          } else if (state.status == AuthStatus.authenticated) {
            context.pushReplacementNamed(AppRoutes.homeName);
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Set Up PIN'),
            automaticallyImplyLeading: false, // Prevent back navigation
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
                          const Icon(
                            Icons.lock_rounded,
                            size: 48,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'Create your secure PIN',
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
                            'Set a 4-digit PIN for quick and secure access to your hostel account.',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // Create PIN Field
                          BlocSelector<AuthFormCubit, AuthFormState, bool>(
                            selector: (state) => state.obscurePin,
                            builder: (context, obscurePin) {
                              return AppTextField(
                                controller: _pinController,
                                label: 'Create 4-digit PIN',
                                prefixIcon: const Icon(Icons.dialpad_rounded),
                                obscureText: obscurePin,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                maxLength: 4,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
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
                                  tooltip: obscurePin ? 'Show PIN' : 'Hide PIN',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a 4-digit PIN.';
                                  }
                                  if (value.length != 4) {
                                    return 'PIN must contain exactly 4 digits.';
                                  }
                                  return null;
                                },
                              );
                            },
                          ),

                          const SizedBox(height: AppSpacing.md),

                          // Confirm PIN Field
                          BlocSelector<AuthFormCubit, AuthFormState, bool>(
                            selector: (state) => state.obscureConfirmPin,
                            builder: (context, obscureConfirmPin) {
                              return AppTextField(
                                controller: _confirmPinController,
                                label: 'Confirm PIN',
                                prefixIcon: const Icon(Icons.dialpad_rounded),
                                obscureText: obscureConfirmPin,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                maxLength: 4,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                                onFieldSubmitted: (_) => _submit(context),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscureConfirmPin
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppColors.textSecondary,
                                  ),
                                  onPressed: () => context
                                      .read<AuthFormCubit>()
                                      .toggleConfirmPinVisibility(),
                                  tooltip: obscureConfirmPin
                                      ? 'Show PIN'
                                      : 'Hide PIN',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please confirm your 4-digit PIN.';
                                  }
                                  if (value.length != 4) {
                                    return 'PIN must contain exactly 4 digits.';
                                  }
                                  if (value != _pinController.text) {
                                    return 'PINs do not match.';
                                  }
                                  return null;
                                },
                              );
                            },
                          ),

                          const SizedBox(height: AppSpacing.xl),

                          // Set PIN Button
                          BlocSelector<AuthCubit, AuthState, bool>(
                            selector: (state) =>
                                state.status == AuthStatus.loading,
                            builder: (context, isLoading) {
                              return AppButton(
                                label: 'Set PIN & Continue',
                                isLoading: isLoading,
                                isFullWidth: true,
                                onPressed:
                                    isLoading ? null : () => _submit(context),
                              );
                            },
                          ),

                          const SizedBox(height: AppSpacing.lg),

                          Text(
                            'Your PIN is stored securely on this device.',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
