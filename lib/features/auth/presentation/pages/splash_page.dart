import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/presentation/authenticated_destination_resolver.dart';
import '../../domain/entities/user_role.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

/// Central navigation decision-point.
///
/// Auth flow:
///   roleSelectionRequired → /role-selection
///   loginRequired         → /owner/login or /manager/login (based on selectedRole)
///   pinLockRequired       → /pin-lock
///   authenticated         → AuthenticatedDestinationResolver → /home or /hostel/setup
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthCubit>().checkAuthStatus();
    });
  }

  void _retry() {
    context.read<AuthCubit>().checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case AuthStatus.roleSelectionRequired:
            context.goNamed(AppRoutes.roleSelectionName);

          case AuthStatus.loginRequired:
            final role = state.selectedRole;
            if (role == UserRole.manager) {
              context.goNamed(AppRoutes.managerLoginName);
            } else {
              // Default to owner login (also handles null role gracefully)
              context.goNamed(AppRoutes.ownerLoginName);
            }

          case AuthStatus.pinLockRequired:
            context.goNamed(AppRoutes.pinLockName);

          case AuthStatus.authenticated:
            // Handled in builder below via AuthenticatedDestinationResolver
            break;

          default:
            break;
        }
      },
      builder: (context, state) {
        // When authenticated, overlay the resolver to check hostel setup.
        if (state.status == AuthStatus.authenticated && state.user != null) {
          return AuthenticatedDestinationResolver(
            user: state.user!,
            onNavigate: (routeName) => context.goNamed(routeName),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.lg,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 260,
                      height: 260,
                      child: Lottie.asset(
                        'assets/lottie/hostel_splash.json',
                        repeat: true,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Hostel Management',
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -1,
                                color: AppColors.textPrimary,
                              ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Manage your hostel efficiently',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    if (state.status == AuthStatus.failure) ...[
                      Text(
                        state.errorMessage ?? 'Something went wrong.',
                        style: const TextStyle(
                          color: AppColors.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      AppButton(
                        label: 'Retry',
                        onPressed: _retry,
                      ),
                    ] else ...[
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
