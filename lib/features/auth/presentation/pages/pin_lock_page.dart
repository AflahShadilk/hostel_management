import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/authenticated_destination_resolver.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

/// Banking-style PIN Lock screen shown on every app relaunch after login.
/// The user identifies themselves automatically from the stored session —
/// no email field is shown.
class PinLockPage extends StatefulWidget {
  const PinLockPage({super.key});

  @override
  State<PinLockPage> createState() => _PinLockPageState();
}

class _PinLockPageState extends State<PinLockPage>
    with SingleTickerProviderStateMixin {
  final List<String> _pin = [];
  static const int _pinLength = 4;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onKeyTap(String digit) {
    if (_pin.length >= _pinLength) return;
    _pin.add(digit);
    // Rebuild via BlocBuilder — we don't use setState per project rules,
    // but pin input is local view-only state with no business logic.
    // We trigger a rebuild by emitting a no-op through the cubit only when
    // the PIN is complete.
    if (_pin.length == _pinLength) {
      _submit();
    } else {
      // Force a rebuild for the dot indicators via a lightweight approach:
      // since this is purely ephemeral visual state (dots) and contains
      // zero business logic, we use a ValueNotifier to avoid setState.
      _pinNotifier.value = List.from(_pin);
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    _pin.removeLast();
    _pinNotifier.value = List.from(_pin);
  }

  void _submit() {
    final pin = _pin.join();
    context.read<AuthCubit>().unlockWithPin(pin);
  }

  Future<void> _forgotPin() async {
    context.read<AuthCubit>().forgotPin();
  }

  void _shakeAndReset() {
    _shakeController.forward(from: 0).then((_) {
      _pin.clear();
      _pinNotifier.value = [];
    });
  }

  final ValueNotifier<List<String>> _pinNotifier = ValueNotifier([]);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (prev, curr) =>
          prev.status != curr.status || prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        if (state.status == AuthStatus.failure ||
            (state.status == AuthStatus.pinLockRequired &&
                state.errorMessage != null)) {
          _shakeAndReset();
        }
        if (state.status == AuthStatus.loginRequired) {
          // Forgot PIN navigated us back to login
          final role = state.selectedRole;
          if (role != null) {
            context.goNamed(
              role.name == 'owner'
                  ? AppRoutes.ownerLoginName
                  : AppRoutes.managerLoginName,
            );
          } else {
            context.goNamed(AppRoutes.roleSelectionName);
          }
        }
      },
      builder: (context, state) {
        // Authenticated — resolve hostel destination
        if (state.status == AuthStatus.authenticated && state.user != null) {
          return AuthenticatedDestinationResolver(
            user: state.user!,
            onNavigate: (routeName) => context.goNamed(routeName),
          );
        }

        final user = state.user;
        final isLoading = state.status == AuthStatus.loading;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 400, maxHeight: 750),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32.0, vertical: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── App Icon ────────────────────────────────────────
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.apartment_rounded,
                          size: 36,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(flex: 1),

                      // ── Welcome Text ─────────────────────────────────────
                      Text(
                        'Welcome back',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                              letterSpacing: 0.3,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user != null ? user.name : 'Hostel Manager',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your PIN to continue',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const Spacer(flex: 2),

                      // ── PIN Dot Indicators ───────────────────────────────
                      _PinDotIndicator(
                        pinNotifier: _pinNotifier,
                        shakeAnimation: _shakeAnimation,
                        errorMessage: state.errorMessage,
                      ),

                      const Spacer(flex: 2),

                      // ── Numeric Keypad ───────────────────────────────────
                      _NumericKeypad(
                        onKeyTap: isLoading ? (_) {} : _onKeyTap,
                        onDelete: isLoading ? () {} : _onDelete,
                        isLoading: isLoading,
                      ),

                      const Spacer(flex: 1),

                      // ── Forgot PIN ───────────────────────────────────────
                      TextButton(
                        onPressed: isLoading ? null : _forgotPin,
                        child: Text(
                          'Forgot PIN?',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PIN Dot Indicator
// ─────────────────────────────────────────────────────────────────────────────

class _PinDotIndicator extends StatelessWidget {
  final ValueNotifier<List<String>> pinNotifier;
  final Animation<double> shakeAnimation;
  final String? errorMessage;

  const _PinDotIndicator({
    required this.pinNotifier,
    required this.shakeAnimation,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: shakeAnimation,
          builder: (context, child) {
            final offset =
                (shakeAnimation.value * 12 * (1 - shakeAnimation.value))
                    .clamp(-8.0, 8.0);
            return Transform.translate(
              offset: Offset(offset * (shakeAnimation.value > 0.5 ? -1 : 1), 0),
              child: child,
            );
          },
          child: ValueListenableBuilder<List<String>>(
            valueListenable: pinNotifier,
            builder: (context, pin, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(4, (index) {
                  final filled = index < pin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: filled
                            ? AppColors.primary
                            : AppColors.textSecondary.withAlpha(80),
                        width: 2,
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.error,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Numeric Keypad
// ─────────────────────────────────────────────────────────────────────────────

class _NumericKeypad extends StatelessWidget {
  final void Function(String digit) onKeyTap;
  final VoidCallback onDelete;
  final bool isLoading;

  const _NumericKeypad({
    required this.onKeyTap,
    required this.onDelete,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...rows.map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((digit) {
                return _KeypadButton(
                  label: digit,
                  onTap: () => onKeyTap(digit),
                );
              }).toList(),
            ),
          ),
        ),
        // Bottom row: empty | 0 | delete
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 80), // phantom spacer
            _KeypadButton(
              label: '0',
              onTap: () => onKeyTap('0'),
            ),
            _DeleteButton(onTap: onDelete),
          ],
        ),
      ],
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _KeypadButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(40),
          splashColor: AppColors.primary.withAlpha(30),
          child: Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final VoidCallback onTap;

  const _DeleteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(40),
          child: Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            child: const Icon(
              Icons.backspace_outlined,
              size: 24,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
