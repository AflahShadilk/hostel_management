import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


import '../router/app_routes.dart';
import '../widgets/app_loading_indicator.dart';
import '../theme/app_colors.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/domain/entities/user_role.dart';
import '../../features/hostel/presentation/cubit/hostel_cubit.dart';
import '../../features/hostel/presentation/cubit/hostel_state.dart';
import '../../features/hostel/presentation/cubit/hostel_status.dart';

/// A focused presentation-layer widget that resolves the correct navigation
/// destination for an authenticated [user].
///
/// Rules:
/// - Manager  → Home immediately (no hostel check).
/// - Owner    → [HostelCubit.checkHostelSetup] → Home | HostelSetup.
///
/// This widget is placed in a [BlocListener] inside each page that needs to
/// respond to [AuthStatus.authenticated].  It eliminates the duplication that
/// would arise from copy-pasting hostel-check logic inside [SplashPage],
/// [LoginPage], and [PinSetupPage].
///
/// The widget itself never navigates — it triggers [HostelCubit.checkHostelSetup]
/// and listens for the result, then delegates the actual navigation call to the
/// caller-supplied [onNavigate] callback. This keeps routing in the presentation
/// layer and out of Cubits.
class AuthenticatedDestinationResolver extends StatefulWidget {
  final UserEntity user;

  /// Called once per resolution with the resolved route name.
  /// The callback receives either [AppRoutes.homeName] or
  /// [AppRoutes.hostelSetupName].
  final void Function(String routeName) onNavigate;

  const AuthenticatedDestinationResolver({
    super.key,
    required this.user,
    required this.onNavigate,
  });

  @override
  State<AuthenticatedDestinationResolver> createState() =>
      _AuthenticatedDestinationResolverState();
}

class _AuthenticatedDestinationResolverState
    extends State<AuthenticatedDestinationResolver> {
  bool _checkTriggered = false;

  @override
  void initState() {
    super.initState();
    // Managers go straight to Home — no hostel check required.
    if (widget.user.role == UserRole.manager) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onNavigate(AppRoutes.homeName);
        }
      });
      return;
    }

    // Owner — trigger hostel check exactly once.
    final userId = widget.user.id;
    if (userId != null && userId > 0) {
      _checkTriggered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<HostelCubit>().checkHostelSetup(userId);
        }
      });
    }
  }

  void _retry() {
    final userId = widget.user.id;
    if (userId != null && userId > 0 && mounted) {
      context.read<HostelCubit>().checkHostelSetup(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Managers bypass this listener and never see the hostel loading state.
    if (widget.user.role == UserRole.manager) {
      return const _LoadingBody();
    }

    return BlocListener<HostelCubit, HostelState>(
      listenWhen: (previous, current) =>
          previous.status != current.status && _checkTriggered,
      listener: (context, state) {
        if (state.status == HostelStatus.configured) {
          widget.onNavigate(AppRoutes.homeName);
        } else if (state.status == HostelStatus.notConfigured) {
          widget.onNavigate(AppRoutes.hostelSetupName);
        }
        // failure is handled by the builder below — stays on loading screen
        // so the user can retry safely.
      },
      child: BlocBuilder<HostelCubit, HostelState>(
        builder: (context, state) {
          if (state.status == HostelStatus.failure) {
            return _FailureBody(onRetry: _retry);
          }
          return const _LoadingBody();
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal sub-widgets
// ---------------------------------------------------------------------------

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(child: AppLoadingIndicator()),
      ),
    );
  }
}

class _FailureBody extends StatelessWidget {
  final VoidCallback onRetry;

  const _FailureBody({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Unable to load your account details.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
