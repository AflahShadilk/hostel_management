// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/constants/rent_status_constants.dart';
import '../../../domain/entities/stay_entity.dart';
import '../../cubit/stay/stay_cubit.dart';
import '../../../../tenant/presentation/cubit/tenant_cubit.dart';
import '../../../../tenant/presentation/cubit/tenant_state.dart';

class StayDetailsPage extends StatefulWidget {
  final StayEntity? stay;
  const StayDetailsPage({super.key, required this.stay});

  @override
  State<StayDetailsPage> createState() => _StayDetailsPageState();
}

class _StayDetailsPageState extends State<StayDetailsPage> {
  bool _checkingOut = false;

  String _date(DateTime? value) {
    if (value == null) return '—';
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  Future<void> _confirmCheckout(
      BuildContext context, StayEntity stay) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Confirm Checkout'),
        content: Text(
          'Checking out Tenant #${stay.tenantId} from Room ${stay.roomId} / Bed ${stay.bedId}.\n\n'
          'This will:\n'
          '• Mark the stay as Checked Out\n'
          '• Release the bed\n'
          '• Update room occupancy\n\n'
          'Financial history will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Checkout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _checkingOut = true);
      try {
        await context
            .read<TenantCubit>()
            .checkOutTenant(stay.tenantId, bedId: stay.bedId);
        if (mounted) {
          // Reload stay list and pop back
          context.read<StayCubit>().loadAllStays();
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _checkingOut = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Checkout failed: $e'),
                backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stay = widget.stay;
    if (stay == null) {
      return const Scaffold(
          body: Center(child: Text('Stay record not found.')));
    }

    final isActive = stay.status == StayStatus.active;

    return BlocListener<TenantCubit, TenantState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == TenantOperationStatus.failure &&
            state.errorMessage != null &&
            _checkingOut) {
          setState(() => _checkingOut = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Stay Details'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Status banner
            _buildStatusBanner(context, stay.status),
            const SizedBox(height: AppSpacing.md),
            // Details card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stay Information',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const Divider(),
                    _DetailRow('Tenant', 'Tenant #${stay.tenantId}'),
                    _DetailRow('Room', 'Room #${stay.roomId}'),
                    _DetailRow('Bed', 'Bed #${stay.bedId}'),
                    _DetailRow('Check-in Date', _date(stay.checkInDate)),
                    if (stay.checkOutDate != null)
                      _DetailRow('Check-out Date', _date(stay.checkOutDate)),
                    if (stay.expectedCheckoutDate != null)
                      _DetailRow(
                          'Expected Checkout', _date(stay.expectedCheckoutDate)),
                    _DetailRow('Monthly Rent',
                        '₹${stay.monthlyRentSnapshot.toStringAsFixed(2)}'),
                    _DetailRow('Daily Rate',
                        '₹${stay.dailyRate.toStringAsFixed(2)}'),
                  ],
                ),
              ),
            ),
            // Checkout button — only for active stays
            if (isActive) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: _checkingOut
                    ? null
                    : () => _confirmCheckout(context, stay),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: _checkingOut
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.logout_rounded),
                label: Text(_checkingOut ? 'Processing…' : 'Checkout Tenant'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context, String status) {
    Color color;
    IconData icon;
    String label;
    switch (status) {
      case StayStatus.active:
        color = AppColors.success;
        icon = Icons.check_circle_outline;
        label = 'Active Stay';
        break;
      case StayStatus.checkedOut:
        color = AppColors.textSecondary;
        icon = Icons.logout_rounded;
        label = 'Checked Out';
        break;
      default:
        color = AppColors.warning;
        icon = Icons.info_outline;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 160,
                child: Text(label,
                    style:
                        const TextStyle(fontWeight: FontWeight.w600))),
            Expanded(child: Text(value)),
          ],
        ),
      );
}
