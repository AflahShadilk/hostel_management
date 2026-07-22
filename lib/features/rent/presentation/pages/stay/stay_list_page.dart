// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_empty_state.dart';
import '../../../../../core/widgets/app_dashboard_ui.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../domain/constants/rent_status_constants.dart';
import '../../../domain/entities/stay_entity.dart';
import '../../cubit/stay/stay_cubit.dart';
import '../../cubit/stay/stay_state.dart';
import '../../cubit/checkout/checkout_cubit.dart';
import '../../cubit/checkout/checkout_state.dart';
import '../../../../tenant/presentation/cubit/tenant_cubit.dart';
import '../../../../tenant/presentation/cubit/tenant_state.dart';

class StayListPage extends StatefulWidget {
  const StayListPage({super.key});

  @override
  State<StayListPage> createState() => _StayListPageState();
}

class _StayListPageState extends State<StayListPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  bool _isSearchActive = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<StayCubit>().loadAllStays();
        context.read<CheckoutCubit>().loadAllCheckoutSettlements();
        if (context.read<TenantCubit>().state.tenants.isEmpty) {
          context.read<TenantCubit>().loadTenants();
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _date(DateTime? value) {
    if (value == null) return '—';
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    final tenantState = context.watch<TenantCubit>().state;
    return BlocListener<StayCubit, StayState>(
      listener: (context, state) {
        if (state is StayError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Stay Records'),
          actions: [
            IconButton(
              icon: Icon(_isSearchActive ? Icons.close : Icons.search),
              tooltip: _isSearchActive ? 'Close search' : 'Search stays',
              onPressed: () {
                setState(() {
                  _isSearchActive = !_isSearchActive;
                  if (!_isSearchActive) {
                    _searchController.clear();
                    _searchQuery = '';
                  }
                });
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'All Stays'),
              Tab(text: 'Checkout History'),
            ],
          ),
        ),
        body: Column(
          children: [
            if (_isSearchActive)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: AppTextField(
                  controller: _searchController,
                  hint: 'Search by name, phone, room, bed...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  onChanged: (query) {
                    setState(() => _searchQuery = query);
                  },
                ),
              ),
            Expanded(
              child: BlocBuilder<StayCubit, StayState>(
                builder: (context, state) {
                  if (state is StayLoading || state is StayInitial) {
                    return const Center(child: AppLoadingIndicator());
                  }
                  if (state is StayEmpty) {
                    return const AppEmptyState(
                      icon: Icons.hotel_outlined,
                      title: 'No stay records yet',
                      message:
                          'Stays are created automatically when a tenant is assigned a bed.',
                    );
                  }
                  if (state is StayLoaded) {
                    final allStays = state.stays;
                    return RefreshIndicator(
                      onRefresh: () async {
                        await context.read<StayCubit>().loadAllStays();
                        await context.read<CheckoutCubit>().loadAllCheckoutSettlements();
                      },
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _StayList(
                            stays: allStays,
                            date: _date,
                            tenantState: tenantState,
                            emptyMessage: 'No stay records.',
                            searchQuery: _searchQuery,
                          ),
                          _CheckoutHistory(
                            tenantState: tenantState,
                            searchQuery: _searchQuery,
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StayList extends StatelessWidget {
  final List<StayEntity> stays;
  final String Function(DateTime?) date;
  final String emptyMessage;
  final TenantState tenantState;
  final String searchQuery;

  const _StayList({
    required this.stays,
    required this.date,
    required this.emptyMessage,
    required this.tenantState,
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    final query = searchQuery.trim().toLowerCase();
    final filteredStays = query.isEmpty
        ? stays
        : stays.where((stay) {
            final matches = tenantState.tenants
                .where((tenant) => tenant.id == stay.tenantId)
                .toList();
            final tenant = matches.isEmpty ? null : matches.first;

            final name = tenant?.fullName.toLowerCase() ?? '';
            final phone = tenant?.phoneNumber.toLowerCase() ?? '';
            final roomStr = 'room ${stay.roomId}'.toLowerCase();
            final roomNum = stay.roomId.toString();
            final bedStr = 'bed ${stay.bedId}'.toLowerCase();
            final bedNum = stay.bedId.toString();

            return name.contains(query) ||
                phone.contains(query) ||
                roomStr.contains(query) ||
                roomNum == query ||
                bedStr.contains(query) ||
                bedNum == query;
          }).toList();

    if (filteredStays.isEmpty) {
      return Center(
        child: AppEmptyState(
          icon: query.isNotEmpty ? Icons.search_off : Icons.hotel_outlined,
          title: query.isNotEmpty ? 'No results found' : emptyMessage,
          message: query.isNotEmpty ? 'No stay records match your search.' : null,
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: filteredStays.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) => _StayCard(
        stay: filteredStays[index],
        date: date,
        tenantName: _tenantName(tenantState, filteredStays[index].tenantId),
        phoneNumber: _tenantPhone(tenantState, filteredStays[index].tenantId),
      ),
    );
  }

  String _tenantName(TenantState tenantState, int tenantId) {
    final matches = tenantState.tenants
        .where((tenant) => tenant.id == tenantId)
        .toList();
    return matches.isEmpty ? 'Tenant information unavailable' : matches.first.fullName;
  }

  String? _tenantPhone(TenantState tenantState, int tenantId) {
    final matches = tenantState.tenants
        .where((tenant) => tenant.id == tenantId)
        .toList();
    return matches.isEmpty ? null : matches.first.phoneNumber;
  }
}

class _CheckoutHistory extends StatelessWidget {
  const _CheckoutHistory({
    required this.tenantState,
    this.searchQuery = '',
  });

  final TenantState tenantState;
  final String searchQuery;

  @override
  Widget build(BuildContext context) => BlocBuilder<CheckoutCubit, CheckoutState>(
        builder: (context, state) {
          if (state is CheckoutLoading || state is CheckoutInitial) {
            return const Center(child: AppLoadingIndicator());
          }
          if (state is CheckoutEmpty) {
            return const AppEmptyState(
              icon: Icons.history_outlined,
              title: 'No checkout history',
            );
          }
          if (state is CheckoutLoaded) {
            final query = searchQuery.trim().toLowerCase();
            final allStays = context.read<StayCubit>().state is StayLoaded
                ? (context.read<StayCubit>().state as StayLoaded).stays
                : const <StayEntity>[];

            final filteredSettlements = query.isEmpty
                ? state.settlements
                : state.settlements.where((settlement) {
                    final matchingStays = allStays
                        .where((stay) => stay.id == settlement.stayId)
                        .toList();
                    final stay = matchingStays.isEmpty ? null : matchingStays.first;
                    final tenantId = stay?.tenantId;
                    final tenants = tenantId == null
                        ? const []
                        : tenantState.tenants
                            .where((tenant) => tenant.id == tenantId)
                            .toList();
                    final tenant = tenants.isEmpty ? null : tenants.first;

                    final name = tenant?.fullName.toLowerCase() ?? '';
                    final phone = tenant?.phoneNumber.toLowerCase() ?? '';
                    final roomStr =
                        stay != null ? 'room ${stay.roomId}'.toLowerCase() : '';
                    final roomNum = stay != null ? stay.roomId.toString() : '';
                    final bedStr =
                        stay != null ? 'bed ${stay.bedId}'.toLowerCase() : '';
                    final bedNum = stay != null ? stay.bedId.toString() : '';

                    return name.contains(query) ||
                        phone.contains(query) ||
                        roomStr.contains(query) ||
                        roomNum == query ||
                        bedStr.contains(query) ||
                        bedNum == query;
                  }).toList();

            if (filteredSettlements.isEmpty) {
              return Center(
                child: AppEmptyState(
                  icon: query.isNotEmpty ? Icons.search_off : Icons.history_outlined,
                  title: query.isNotEmpty ? 'No results found' : 'No checkout history',
                  message: query.isNotEmpty ? 'No checkout records match your search.' : null,
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: filteredSettlements.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final settlement = filteredSettlements[index];
                final matchingStays = allStays
                    .where((stay) => stay.id == settlement.stayId)
                    .toList();
                final tenantId = matchingStays.isEmpty ? null : matchingStays.first.tenantId;
                final tenants = tenantId == null ? const [] : tenantState.tenants.where((tenant) => tenant.id == tenantId).toList();
                final tenant = tenants.isEmpty ? null : tenants.first;
                return AppDashboardCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(tenant?.fullName ?? 'Tenant unavailable'),
                    subtitle: Text('Refund: ₹${settlement.refundAmount.toStringAsFixed(2)}'),
                    trailing: Text('₹${settlement.finalAmount.toStringAsFixed(2)}'),
                    onTap: () => context.pushNamed(
                      AppRoutes.checkoutDetailsName,
                      pathParameters: {'checkoutId': settlement.id!.toString()},
                      extra: settlement,
                    ),
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      );
}

class _StayCard extends StatelessWidget {
  final StayEntity stay;
  final String Function(DateTime?) date;
  final String tenantName;
  final String? phoneNumber;

  const _StayCard({
    required this.stay,
    required this.date,
    required this.tenantName,
    required this.phoneNumber,
  });

  Color _statusColor(String status) {
    switch (status) {
      case StayStatus.active:
        return AppColors.success;
      case StayStatus.checkedOut:
        return AppColors.textSecondary;
      case 'checkout_pending':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case StayStatus.active:
        return 'Active';
      case StayStatus.checkedOut:
        return 'Checked Out';
      case 'checkout_pending':
        return 'Checkout Pending';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(stay.status);
    return AppDashboardCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.pushNamed(
          AppRoutes.stayDetailsName,
          pathParameters: {'stayId': stay.id!.toString()},
          extra: stay,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tenantName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: statusColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      _statusLabel(stay.status),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (phoneNumber != null) ...[
                Text(
                  phoneNumber!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              Row(
                children: [
                  const Icon(Icons.meeting_room_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('Room ${stay.roomId}  •  Bed ${stay.bedId}',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.login_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text('Check-in: ${date(stay.checkInDate)}',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  if (stay.checkOutDate != null)
                    Row(
                      children: [
                        const Icon(Icons.logout_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text('Check-out: ${date(stay.checkOutDate)}',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
