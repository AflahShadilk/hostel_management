import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_dashboard_ui.dart';
import '../../domain/entities/tenant_entity.dart';
import '../../domain/entities/tenant_status.dart';
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
  final VoidCallback? onCheckOut;
  final VoidCallback? onTransfer;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onCallTenant;
  final VoidCallback? onCallGuardian;
  final VoidCallback? onSms;

  const TenantCard({
    super.key,
    required this.tenant,
    this.roomLabel,
    this.bedLabel,
    this.actionsEnabled = true,
    this.onCheckOut,
    this.onTransfer,
    this.onEdit,
    this.onDelete,
    this.onWhatsApp,
    this.onCallTenant,
    this.onCallGuardian,
    this.onSms,
  });

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppDashboardCard(
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
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.xs,
              children: [
                if (onWhatsApp != null ||
                    onCallTenant != null ||
                    onCallGuardian != null ||
                    onSms != null)
                  PopupMenuButton<_TenantCommunicationAction>(
                    icon: const Icon(Icons.more_vert_outlined, size: 20),
                    tooltip: 'Contact tenant',
                    onSelected: (action) {
                      switch (action) {
                        case _TenantCommunicationAction.whatsApp:
                          onWhatsApp?.call();
                        case _TenantCommunicationAction.callTenant:
                          onCallTenant?.call();
                        case _TenantCommunicationAction.callGuardian:
                          onCallGuardian?.call();
                        case _TenantCommunicationAction.sms:
                          onSms?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      if (onWhatsApp != null)
                        const PopupMenuItem(
                            value: _TenantCommunicationAction.whatsApp,
                            child: ListTile(
                                leading: Icon(Icons.chat_outlined),
                                title: Text('WhatsApp'))),
                      if (onCallTenant != null)
                        const PopupMenuItem(
                            value: _TenantCommunicationAction.callTenant,
                            child: ListTile(
                                leading: Icon(Icons.call_outlined),
                                title: Text('Call Tenant'))),
                      if (onCallGuardian != null)
                        const PopupMenuItem(
                            value: _TenantCommunicationAction.callGuardian,
                            child: ListTile(
                                leading: Icon(Icons.contact_phone_outlined),
                                title: Text('Call Guardian'))),
                      if (onSms != null)
                        const PopupMenuItem(
                            value: _TenantCommunicationAction.sms,
                            child: ListTile(
                                leading: Icon(Icons.sms_outlined),
                                title: Text('SMS'))),
                    ],
                  ),
                if (tenant.status == TenantStatus.active)
                  IconButton(
                    icon: const Icon(Icons.exit_to_app_outlined, size: 20),
                    tooltip: 'Check Out Tenant',
                    color: AppColors.warning,
                    onPressed: actionsEnabled ? onCheckOut : null,
                  ),
                if (tenant.status == TenantStatus.active)
                  IconButton(
                    icon: const Icon(Icons.swap_horiz_outlined, size: 20),
                    tooltip: 'Transfer Bed',
                    color: AppColors.primary,
                    onPressed: actionsEnabled ? onTransfer : null,
                  ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Edit Tenant',
                  color: AppColors.primary,
                  onPressed: actionsEnabled ? onEdit : null,
                ),
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
    );
  }
}

enum _TenantCommunicationAction { whatsApp, callTenant, callGuardian, sms }

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
