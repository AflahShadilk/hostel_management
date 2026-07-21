import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/user_role.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

/// Modern Material 3 role selection page.
///
/// Cards are tap targets only — selecting a card calls [AuthCubit.selectRole]
/// which persists the role and emits [AuthStatus.loginRequired].
/// The [BlocListener] in [SplashPage] / here handles the subsequent navigation.
class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  UserRole? _selectedRole;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onRoleSelected(BuildContext context, UserRole role) {
    _selectedRole = role;
    context.read<AuthCubit>().selectRole(role);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == AuthStatus.loginRequired) {
          final role = state.selectedRole ?? _selectedRole;
          if (role == UserRole.owner) {
            context.goNamed(AppRoutes.ownerLoginName);
          } else if (role == UserRole.manager) {
            context.goNamed(AppRoutes.managerLoginName);
          }
        }
      },
      builder: (context, state) {
        final isLoading = state.status == AuthStatus.loading;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;

                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 48 : 24,
                      vertical: 32,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 16),

                            // ── Hero Icon ──────────────────────────────────
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2563EB),
                                    Color(0xFF0891B2),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppColors.primary.withAlpha(60),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.apartment_rounded,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 28),

                            // ── Heading ────────────────────────────────────
                            Text(
                              'Hostel Management',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Who are you signing in as?',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 40),

                            // ── Role Cards ─────────────────────────────────
                            if (isWide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _RoleCard(
                                      role: UserRole.owner,
                                      icon: Icons.business_center_rounded,
                                      title: 'Owner',
                                      tagline: 'Full access',
                                      description:
                                          'Manage hostels, rooms, tenants, payments and reports.',
                                      accentColor: AppColors.primary,
                                      isLoading: isLoading,
                                      onTap: () => _onRoleSelected(
                                          context, UserRole.owner),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: _RoleCard(
                                      role: UserRole.manager,
                                      icon: Icons.badge_rounded,
                                      title: 'Manager',
                                      tagline: 'Assigned access',
                                      description:
                                          'Access assigned hostel management operations.',
                                      accentColor: AppColors.secondary,
                                      isLoading: isLoading,
                                      onTap: () => _onRoleSelected(
                                          context, UserRole.manager),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Column(
                                children: [
                                  _RoleCard(
                                    role: UserRole.owner,
                                    icon: Icons.business_center_rounded,
                                    title: 'Owner',
                                    tagline: 'Full access',
                                    description:
                                        'Manage hostels, rooms, tenants, payments and reports.',
                                    accentColor: AppColors.primary,
                                    isLoading: isLoading,
                                    onTap: () => _onRoleSelected(
                                        context, UserRole.owner),
                                  ),
                                  const SizedBox(height: 16),
                                  _RoleCard(
                                    role: UserRole.manager,
                                    icon: Icons.badge_rounded,
                                    title: 'Manager',
                                    tagline: 'Assigned access',
                                    description:
                                        'Access assigned hostel management operations.',
                                    accentColor: AppColors.secondary,
                                    isLoading: isLoading,
                                    onTap: () => _onRoleSelected(
                                        context, UserRole.manager),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 36),

                            // ── Footer note ────────────────────────────────
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 14,
                                  color: AppColors.textSecondary.withAlpha(160),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'First time? Create an account after selecting your role.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary
                                          .withAlpha(160),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Role Card — tap target only, no buttons inside
// ─────────────────────────────────────────────────────────────────────────────

class _RoleCard extends StatefulWidget {
  final UserRole role;
  final IconData icon;
  final String title;
  final String tagline;
  final String description;
  final Color accentColor;
  final bool isLoading;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.icon,
    required this.title,
    required this.tagline,
    required this.description,
    required this.accentColor,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..translate(0.0, _hovering ? -4.0 : 0.0),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: widget.isLoading ? null : widget.onTap,
            borderRadius: BorderRadius.circular(20),
            splashColor: widget.accentColor.withAlpha(20),
            highlightColor: widget.accentColor.withAlpha(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _hovering
                      ? widget.accentColor.withAlpha(120)
                      : AppColors.border,
                  width: _hovering ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _hovering
                        ? widget.accentColor.withAlpha(30)
                        : Colors.black.withAlpha(8),
                    blurRadius: _hovering ? 20 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon container
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: widget.accentColor.withAlpha(18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 26,
                      color: widget.accentColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.accentColor.withAlpha(18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.tagline,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: widget.accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Text(
                    widget.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // CTA row at bottom
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (widget.isLoading)
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: widget.accentColor,
                          ),
                        )
                      else
                        Row(
                          children: [
                            Text(
                              'Continue',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: widget.accentColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: widget.accentColor,
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
