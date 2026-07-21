import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_empty_state.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../../domain/constants/rent_status_constants.dart';
import '../../../domain/entities/stay_entity.dart';
import '../../cubit/stay/stay_cubit.dart';
import '../../cubit/stay/stay_state.dart';

class StayListPage extends StatefulWidget {
  const StayListPage({super.key});

  @override
  State<StayListPage> createState() => _StayListPageState();
}

class _StayListPageState extends State<StayListPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<StayCubit>().loadAllStays();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _date(DateTime? value) {
    if (value == null) return '—';
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  @override
  Widget build(BuildContext context) {
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
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Active'),
              Tab(text: 'Checked Out'),
            ],
          ),
        ),
        // No FloatingActionButton — stays are created automatically
        body: BlocBuilder<StayCubit, StayState>(
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
              final activeStays = allStays
                  .where((s) => s.status == StayStatus.active)
                  .toList();
              final checkedOutStays = allStays
                  .where((s) => s.status == StayStatus.checkedOut)
                  .toList();

              return RefreshIndicator(
                onRefresh: () => context.read<StayCubit>().loadAllStays(),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _StayList(
                        stays: allStays, date: _date, emptyMessage: 'No stay records.'),
                    _StayList(
                        stays: activeStays,
                        date: _date,
                        emptyMessage: 'No active stays.'),
                    _StayList(
                        stays: checkedOutStays,
                        date: _date,
                        emptyMessage: 'No checked-out stays.'),
                  ],
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

class _StayList extends StatelessWidget {
  final List<StayEntity> stays;
  final String Function(DateTime?) date;
  final String emptyMessage;

  const _StayList(
      {required this.stays, required this.date, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (stays.isEmpty) {
      return Center(
        child: AppEmptyState(
          icon: Icons.hotel_outlined,
          title: emptyMessage,
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: stays.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) =>
          _StayCard(stay: stays[index], date: date),
    );
  }
}

class _StayCard extends StatelessWidget {
  final StayEntity stay;
  final String Function(DateTime?) date;

  const _StayCard({required this.stay, required this.date});

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
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
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
                      'Tenant #${stay.tenantId}',
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
