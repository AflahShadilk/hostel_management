import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_dashboard_ui.dart';
import '../../../domain/constants/rent_status_constants.dart';
import '../../../domain/entities/stay_entity.dart';
import '../../../../tenant/presentation/cubit/tenant_cubit.dart';

class StayDetailsPage extends StatelessWidget {
  final StayEntity? stay;

  const StayDetailsPage({super.key, required this.stay});

  String _date(DateTime? value) {
    if (value == null) return 'Not checked out';
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  String _duration(StayEntity value) {
    final end = value.checkOutDate ?? DateTime.now();
    final days = end.difference(value.checkInDate).inDays + 1;
    return '$days day${days == 1 ? '' : 's'}';
  }

  String _statusLabel(String status) {
    switch (status) {
      case StayStatus.active:
        return 'Active';
      case StayStatus.checkedOut:
        return 'Checked Out';
      case StayStatus.checkoutPending:
        return 'Pending Settlement';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case StayStatus.active:
        return AppColors.success;
      case StayStatus.checkedOut:
        return AppColors.textSecondary;
      case StayStatus.checkoutPending:
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStay = stay;
    if (currentStay == null) {
      return const Scaffold(
        body: Center(child: Text('Stay record not found.')),
      );
    }

    final tenantState = context.watch<TenantCubit>().state;
    final tenants = tenantState.tenants
        .where((tenant) => tenant.id == currentStay.tenantId)
        .toList();
    final tenant = tenants.isEmpty ? null : tenants.first;
    final viewModels = tenantState.viewModels
        .where((viewModel) => viewModel.tenant.id == currentStay.tenantId)
        .toList();
    final viewModel = viewModels.isEmpty ? null : viewModels.first;
    final statusColor = _statusColor(currentStay.status);
    final isActive = currentStay.status == StayStatus.active;

    return Scaffold(
      appBar: AppBar(title: const Text('Stay Details')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            AppDashboardCard(
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: statusColor.withValues(alpha: .12),
                    foregroundColor: statusColor,
                    child: Text(
                      (tenant?.fullName.isNotEmpty ?? false)
                          ? tenant!.fullName.characters.first.toUpperCase()
                          : '?',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tenant?.fullName ?? 'Tenant information unavailable',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text(
                          tenant?.phoneNumber ?? 'Phone not available',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(_statusLabel(currentStay.status)),
                    backgroundColor: statusColor.withValues(alpha: .12),
                    labelStyle: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppSectionCard(
              title: 'Stay Timeline',
              icon: Icons.calendar_month_outlined,
              child: Column(
                children: [
                  _DetailRow('Room', viewModel?.roomName ?? 'Room ${currentStay.roomId}'),
                  _DetailRow('Bed', viewModel?.bedName ?? 'Bed ${currentStay.bedId}'),
                  _DetailRow('Check-in', _date(currentStay.checkInDate)),
                  _DetailRow('Checkout', _date(currentStay.checkOutDate)),
                  _DetailRow('Stay duration', _duration(currentStay)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppSectionCard(
              title: 'Stay Information',
              icon: Icons.hotel_outlined,
              child: Column(
                children: [
                  _DetailRow('Monthly rent', '₹${currentStay.monthlyRentSnapshot.toStringAsFixed(2)}'),
                  _DetailRow('Expected checkout', _date(currentStay.expectedCheckoutDate)),
                  _DetailRow('Status', _statusLabel(currentStay.status)),
                ],
              ),
            ),
            if (isActive) ...[
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: () => context.pushNamed(
                  AppRoutes.checkoutSettlementFormName,
                  extra: currentStay,
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Open Checkout Settlement'),
              ),
            ],
          ],
        ),
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
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      );
}
