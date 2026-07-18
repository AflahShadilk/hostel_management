import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/tenant_status.dart';

/// Colour-coded chip that reflects a [TenantStatus].
///
/// Matches the visual pattern used by `_RoomStatusChip` in the Room module.
class TenantStatusChip extends StatelessWidget {
  final TenantStatus status;

  const TenantStatusChip({super.key, required this.status});

  Color get _color {
    switch (status) {
      case TenantStatus.active:
        return AppColors.success;
      case TenantStatus.checkedOut:
        return AppColors.warning;
      case TenantStatus.inactive:
        return AppColors.textSecondary;
    }
  }

  String get _label {
    switch (status) {
      case TenantStatus.active:
        return 'Active';
      case TenantStatus.checkedOut:
        return 'Checked Out';
      case TenantStatus.inactive:
        return 'Inactive';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(
        _label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
