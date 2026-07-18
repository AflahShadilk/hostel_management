import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/tenant_entity.dart';
import 'tenant_status_chip.dart';

/// Displays a single [TenantEntity] in a card layout.
///
/// Accepts optional [roomLabel] and [bedLabel] strings that the parent resolves
/// by cross-referencing its Room + Bed data (since TenantEntity only stores bedId).
class TenantCard extends StatelessWidget {
  final TenantEntity tenant;
  final String? roomLabel;
  final String? bedLabel;
  final bool actionsEnabled;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TenantCard({
    super.key,
    required this.tenant,
    this.roomLabel,
    this.bedLabel,
    this.actionsEnabled = true,
    this.onEdit,
    this.onDelete,
  });

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Name + Status chip
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tenant.fullName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tenant.phoneNumber,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TenantStatusChip(status: tenant.status),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: AppSpacing.sm),

            // Info rows
            _InfoRow(
              icon: Icons.meeting_room_outlined,
              label: 'Room',
              value: roomLabel ?? '—',
            ),
            const SizedBox(height: AppSpacing.xs),
            _InfoRow(
              icon: Icons.bed_outlined,
              label: 'Bed',
              value: bedLabel ?? '—',
            ),
            const SizedBox(height: AppSpacing.xs),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Check-in',
              value: _formatDate(tenant.checkInDate),
            ),
            if (tenant.checkOutDate != null) ...[
              const SizedBox(height: AppSpacing.xs),
              _InfoRow(
                icon: Icons.event_available_outlined,
                label: 'Check-out',
                value: _formatDate(tenant.checkOutDate!),
              ),
            ],

            const SizedBox(height: AppSpacing.sm),

            // Action row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Edit Tenant',
                  color: AppColors.primary,
                  onPressed: actionsEnabled ? onEdit : null,
                ),
                const SizedBox(width: AppSpacing.xs),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: 'Delete Tenant',
                  color: AppColors.error,
                  onPressed: actionsEnabled ? onDelete : null,
                ),
              ],
            ),
          ],
        ),
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
