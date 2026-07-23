// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hostel_management/features/tenant/presentation/cubit/tenant_cubit.dart';
import 'package:hostel_management/features/tenant/presentation/cubit/tenant_state.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_empty_state.dart';
import '../../../../../core/widgets/app_dashboard_ui.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../../domain/constants/rent_status_constants.dart';
import '../../../domain/entities/stay_entity.dart';

import '../../cubit/checkout/checkout_cubit.dart';
import '../../cubit/checkout/checkout_state.dart';
import '../../cubit/stay/stay_cubit.dart';
import '../../cubit/stay/stay_state.dart';

/// Entry point for the Checkout workflow.
///
/// Displays all Active stays. Each item has a "Checkout" action that calls
/// [TenantCubit.checkOutTenant] — the same business logic used everywhere else.
///
/// This replaces the old empty "Checkout Settlements" list page.
class CheckoutFlowPage extends StatefulWidget {
  const CheckoutFlowPage({super.key});

  @override
  State<CheckoutFlowPage> createState() => _CheckoutFlowPageState();
}

class _CheckoutFlowPageState extends State<CheckoutFlowPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<StayCubit>().loadAllStays();
        if (context.read<TenantCubit>().state.tenants.isEmpty) {
          context.read<TenantCubit>().loadTenants();
        }
      }
    });
  }

  Future<void> _confirmCheckout(
      BuildContext context, StayEntity stay) async {
    await context.pushNamed(
      AppRoutes.checkoutSettlementFormName,
      extra: stay,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<StayCubit, StayState>(
          listener: (context, state) {
            if (state is StayError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error),
              );
            }
          },
        ),
        BlocListener<CheckoutCubit, CheckoutState>(
          listener: (context, state) {
            if (state is CheckoutError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error),
              );
            } else if (state is CheckoutLoaded) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Checkout completed successfully.'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Checkout'),
        ),
        body: BlocBuilder<StayCubit, StayState>(
          builder: (context, state) {
            if (state is StayLoading || state is StayInitial) {
              return const Center(child: AppLoadingIndicator());
            }

            if (state is StayEmpty) {
              return const AppEmptyState(
                icon: Icons.hotel_outlined,
                title: 'No active stays',
                message: 'All tenants have been checked out.',
              );
            }

            if (state is StayLoaded) {
              final activeStays = state.stays
                  .where((s) => s.status == StayStatus.active)
                  .toList();

              if (activeStays.isEmpty) {
                return const AppEmptyState(
                  icon: Icons.check_circle_outline,
                  title: 'No active stays',
                  message: 'All tenants have been checked out.',
                );
              }

              final isMutating =
                  context.watch<TenantCubit>().state.status ==
                      TenantOperationStatus.checkingOut;
              final tenantState = context.watch<TenantCubit>().state;

              return RefreshIndicator(
                onRefresh: () =>
                    context.read<StayCubit>().loadAllStays(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: activeStays.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final stay = activeStays[index];
                    final tenantMatches = tenantState.tenants
                        .where((tenant) => tenant.id == stay.tenantId)
                        .toList();
                    final tenant = tenantMatches.isEmpty
                        ? null
                        : tenantMatches.first;
                    final tenantViewMatches = tenantState.viewModels
                        .where((viewModel) =>
                            viewModel.tenant.id == stay.tenantId)
                        .toList();
                    final tenantView = tenantViewMatches.isEmpty
                        ? null
                        : tenantViewMatches.first;
                    return _ActiveStayCard(
                      stay: stay,
                      tenantName: tenant?.fullName ?? 'Tenant information unavailable',
                      phoneNumber: tenant?.phoneNumber ?? 'Phone not available',
                      roomName: tenantView?.roomName ?? 'Room ${stay.roomId}',
                      bedName: tenantView?.bedName ?? 'Bed ${stay.bedId}',
                      isMutating: isMutating,
                      onDetails: () => context.pushNamed(
                        AppRoutes.stayDetailsName,
                        pathParameters: {
                          'stayId': stay.id!.toString()
                        },
                        extra: stay,
                      ),
                      onCheckout: () =>
                          _confirmCheckout(context, stay),
                    );
                  },
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _ActiveStayCard extends StatelessWidget {
  final StayEntity stay;
  final String tenantName;
  final String phoneNumber;
  final String roomName;
  final String bedName;
  final bool isMutating;
  final VoidCallback onDetails;
  final VoidCallback onCheckout;

  const _ActiveStayCard({
    required this.stay,
    required this.tenantName,
    required this.phoneNumber,
    required this.roomName,
    required this.bedName,
    required this.isMutating,
    required this.onDetails,
    required this.onCheckout,
  });

  String _date(DateTime? value) {
    if (value == null) return '—';
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AppDashboardCard(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tenantName,
                    style:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'Active',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$roomName / $bedName',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              phoneNumber,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(Icons.meeting_room_outlined,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Room ${stay.roomId}  •  Bed ${stay.bedId}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(Icons.login_outlined,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Check-in: ${_date(stay.checkInDate)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                Text(
                  '₹${stay.monthlyRentSnapshot.toStringAsFixed(0)}/mo',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDetails,
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isMutating ? null : onCheckout,
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.warning),
                    icon: const Icon(Icons.logout_rounded, size: 16),
                    label: const Text('Checkout'),
                  ),
                ),
              ],
            ),
          ],
      ),
    );
  }
}






