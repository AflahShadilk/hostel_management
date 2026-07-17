import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              final maxContentWidth = isWide ? 800.0 : double.infinity;

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.xl),
                      const Icon(
                        Icons.apartment_rounded,
                        size: 48,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Welcome',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        "Choose how you'd like to continue",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildOwnerCard(context)),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(child: _buildManagerCard(context)),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _buildOwnerCard(context),
                            const SizedBox(height: AppSpacing.lg),
                            _buildManagerCard(context),
                          ],
                        ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOwnerCard(BuildContext context) {
    return _RoleCard(
      icon: Icons.business_center_rounded,
      title: 'Owner',
      description: 'Manage your hostel, rooms, tenants, payments and reports.',
      primaryActionText: 'Login',
      onPrimaryAction: () => context.pushNamed(AppRoutes.ownerLoginName),
      secondaryActionText: 'Sign Up',
      onSecondaryAction: () => context.pushNamed(AppRoutes.ownerSignUpName),
    );
  }

  Widget _buildManagerCard(BuildContext context) {
    return _RoleCard(
      icon: Icons.badge_rounded,
      title: 'Manager',
      description: 'Access assigned hostel management operations.',
      primaryActionText: 'Login',
      onPrimaryAction: () => context.pushNamed(AppRoutes.managerLoginName),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String primaryActionText;
  final VoidCallback onPrimaryAction;
  final String? secondaryActionText;
  final VoidCallback? onSecondaryAction;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.primaryActionText,
    required this.onPrimaryAction,
    this.secondaryActionText,
    this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13), // ~0.05 opacity
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            icon,
            size: 40,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: primaryActionText,
            onPressed: onPrimaryAction,
          ),
          if (secondaryActionText != null && onSecondaryAction != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: secondaryActionText!,
              onPressed: onSecondaryAction,
              // Note: if type doesn't exist, we omit it or use an OutlinedButton instead.
              // Assuming we don't have type in AppButton, I will just use AppButton.
            ),
          ],
        ],
      ),
    );
  }
}
