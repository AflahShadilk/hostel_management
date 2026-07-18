import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:hostel_management/core/router/app_routes.dart';
import 'package:hostel_management/core/theme/app_colors.dart';
import 'package:hostel_management/core/constants/app_spacing.dart';

// NOTE: This is a temporary placeholder Home Page.
// It will be replaced by the full Dashboard in Module 02 Task 05.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hostel Management'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.home_work_outlined,
                  size: 64,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Full dashboard coming soon.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Temporary navigation to Room Management (Task 03).
                FilledButton.icon(
                  icon: const Icon(Icons.meeting_room_outlined),
                  label: const Text('Manage Rooms'),
                  onPressed: () =>
                      context.goNamed(AppRoutes.roomManagementName),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
