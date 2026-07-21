import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/bed_entity.dart';
import '../../domain/entities/bed_status.dart';
import '../extensions/bed_presentation_extensions.dart';

class BedCard extends StatelessWidget {
  final BedEntity bed;
  final VoidCallback? onSetInactive;
  final VoidCallback? onReactivate;
  final bool actionsEnabled;

  const BedCard({
    super.key,
    required this.bed,
    this.onSetInactive,
    this.onReactivate,
    this.actionsEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.single_bed_outlined,
                          color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        bed.bedNumber,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _BedStatusChip(status: bed.status),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: AppSpacing.sm),

            // Context/Action row
            Align(
              alignment: Alignment.bottomLeft,
              child: _buildActionRow(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow(BuildContext context) {
    switch (bed.status) {
      case BedStatus.vacant:
        return TextButton.icon(
          onPressed: actionsEnabled ? onSetInactive : null,
          icon: const Icon(Icons.block_outlined, size: 18),
          label: const Text('Set Inactive'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
          ),
        );
      case BedStatus.inactive:
        return TextButton.icon(
          onPressed: actionsEnabled ? onReactivate : null,
          icon: const Icon(Icons.check_circle_outline, size: 18),
          label: const Text('Reactivate'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
          ),
        );
      case BedStatus.occupied:
        return Text(
          'Managed through tenant assignment',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
        );
    }
  }
}

class _BedStatusChip extends StatelessWidget {
  final BedStatus status;

  const _BedStatusChip({required this.status});

  Color get _color {
    switch (status) {
      case BedStatus.vacant:
        return AppColors.success;
      case BedStatus.occupied:
        return AppColors.error;
      case BedStatus.inactive:
        return AppColors.textSecondary;
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
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
