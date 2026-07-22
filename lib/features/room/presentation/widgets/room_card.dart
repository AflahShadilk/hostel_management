import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_dashboard_ui.dart';
import '../../domain/entities/room_entity.dart';
import '../../domain/entities/room_status.dart';
import '../extensions/room_presentation_extensions.dart';

class RoomCard extends StatelessWidget {
  final RoomEntity room;
  final VoidCallback? onManageBeds;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool actionsEnabled;

  const RoomCard({
    super.key,
    required this.room,
    this.onManageBeds,
    this.onEdit,
    this.onDelete,
    this.actionsEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppDashboardCard(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: Room Number + Status chip
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Room ${room.roomNumber}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Floor: ${room.floor}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _RoomStatusChip(status: room.status),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: AppSpacing.sm),

            // Info grid
            _InfoRow(
              icon: Icons.hotel_outlined,
              label: 'Type',
              value: room.roomType.label,
            ),
            const SizedBox(height: AppSpacing.xs),
            _InfoRow(
              icon: Icons.bed_outlined,
              label: 'Beds',
              value: room.numberOfBeds.toString(),
            ),
            const SizedBox(height: AppSpacing.xs),
            _InfoRow(
              icon: Icons.currency_rupee_outlined,
              label: 'Rent',
              value: formatRent(room.monthlyRent),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Action row
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: actionsEnabled ? onManageBeds : null,
                      icon:
                          const Icon(Icons.manage_accounts_outlined, size: 18),
                      label: const Text('Manage Beds'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Edit Room',
                  color: AppColors.primary,
                  onPressed: actionsEnabled ? onEdit : null,
                ),
                const SizedBox(width: AppSpacing.xs),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: 'Delete Room',
                  color: AppColors.error,
                  onPressed: actionsEnabled ? onDelete : null,
                ),
              ],
            ),
          ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _RoomStatusChip extends StatelessWidget {
  final RoomStatus status;

  const _RoomStatusChip({required this.status});

  Color get _color {
    switch (status) {
      case RoomStatus.vacant:
        return AppColors.success;
      case RoomStatus.partiallyOccupied:
        return AppColors.warning;
      case RoomStatus.occupied:
        return AppColors.error;
      case RoomStatus.inactive:
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
