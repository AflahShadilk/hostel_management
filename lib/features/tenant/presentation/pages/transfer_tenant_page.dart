import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../hostel/presentation/cubit/hostel_cubit.dart';
import '../../domain/entities/tenant_entity.dart';
import '../cubit/tenant_cubit.dart';
import '../cubit/tenant_state.dart';
import '../cubit/transfer_tenant_form_cubit.dart';
import '../widgets/bed_selection_widget.dart';

/// Bed transfer page.
///
/// UI state (selected new bed) is fully managed by [TransferTenantFormCubit].
/// Current bed labels are read from the existing [TenantCubit] state.
/// No setState() calls exist in this file.
class TransferTenantPage extends StatelessWidget {
  final TenantEntity? tenant;

  const TransferTenantPage({super.key, required this.tenant});

  @override
  Widget build(BuildContext context) {
    if (tenant == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Transfer Tenant')),
        body: const Center(child: Text('Tenant data not found.')),
      );
    }

    final hostelId = context.read<HostelCubit>().state.hostel?.id;
    if (hostelId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Transfer Tenant')),
        body: const Center(child: Text('Hostel not configured.')),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => TransferTenantFormCubit()),
      ],
      child: BlocListener<TenantCubit, TenantState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          if (state.status == TenantOperationStatus.loaded) {
            if (context.canPop()) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Tenant transferred successfully.')),
              );
              context.pop(true);
            }
          } else if (state.status == TenantOperationStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Transfer failed.'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Transfer Tenant'),
            backgroundColor: AppColors.surface,
            elevation: 0,
            scrolledUnderElevation: 1,
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Transferring: ${tenant!.fullName}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _CurrentBedLabel(tenant: tenant!),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Select New Bed',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // BedSelectionWidget manages its own BedSelectionCubit internally.
                      BlocBuilder<TransferTenantFormCubit, dynamic>(
                        builder: (context, selectedBed) {
                          return BedSelectionWidget(
                            hostelId: hostelId,
                            selectedBed: selectedBed,
                            onBedSelected: (bed) => context
                                .read<TransferTenantFormCubit>()
                                .selectBed(bed),
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      BlocBuilder<TenantCubit, TenantState>(
                        builder: (context, tenantState) {
                          final isTransferring = tenantState.status ==
                                  TenantOperationStatus.transferring ||
                              tenantState.status ==
                                  TenantOperationStatus.loading;
                          return BlocBuilder<TransferTenantFormCubit, dynamic>(
                            builder: (context, selectedBed) {
                              return AppButton(
                                label: 'Transfer Tenant',
                                isLoading: isTransferring,
                                onPressed:
                                    (selectedBed == null || isTransferring)
                                        ? null
                                        : () {
                                            context
                                                .read<TenantCubit>()
                                                .transferTenant(
                                                  tenant!.id!,
                                                  oldBedId: tenant!.bedId!,
                                                  newBedId: selectedBed.id!,
                                                );
                                          },
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Resolves and displays the current bed and room names from [TenantCubit].
/// Never displays raw database IDs to the user.
class _CurrentBedLabel extends StatelessWidget {
  final TenantEntity tenant;
  const _CurrentBedLabel({required this.tenant});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TenantCubit, TenantState>(
      builder: (context, state) {
        // We use the BedSelectionCubit just to check if loading is done —
        // actual current-bed resolution is done via a separate loading mechanism.
        // For the label, we rely on the TenantViewModel (already loaded by TenantCubit).
        final vms = state.viewModels;
        final vm = vms.where((v) => v.tenant.id == tenant.id).firstOrNull;

        final roomLabel = vm?.roomName ?? '—';
        final bedLabel = vm?.bedName ?? '—';

        return Text(
          'Current: $roomLabel · $bedLabel',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        );
      },
    );
  }
}
