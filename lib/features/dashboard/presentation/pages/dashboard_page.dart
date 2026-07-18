import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../hostel/presentation/cubit/hostel_cubit.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_operation_status.dart';
import '../cubit/dashboard_state.dart';
import '../widgets/dashboard_metric_card.dart';
import '../widgets/dashboard_quick_action_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    final hostelState = context.read<HostelCubit>().state;

    // Only load if we have a resolved hostel.
    // Manager fallback handles the null hostel case safely below.
    if (hostelState.hostel?.id != null) {
      context.read<DashboardCubit>().loadDashboard(hostelState.hostel!.id!);
    }
  }

  Future<void> _refresh() async {
    final hostelState = context.read<HostelCubit>().state;
    if (hostelState.hostel?.id != null) {
      await context
          .read<DashboardCubit>()
          .refreshDashboard(hostelState.hostel!.id!);
    }
  }

  Future<void> _navigateManageRooms() async {
    // Wait for the room management page to pop
    await context.pushNamed(AppRoutes.roomManagementName);
    // Refresh dashboard stats when returning
    if (mounted) {
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final hostelState = context.watch<HostelCubit>().state;

    final isManager = authState.user?.role == UserRole.manager;
    final hasHostel = hostelState.hostel != null;
    final hostelName = hostelState.hostel?.name ?? 'Dashboard';

    return Scaffold(
      appBar: AppBar(
        title: Text(hostelName),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthCubit>().logout();
            },
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (isManager && !hasHostel) {
            return const AppEmptyState(
              icon: Icons.info_outline,
              title: 'Access Pending',
              message:
                  'Hostel access for manager accounts will be available after manager assignment is configured.',
            );
          }

          if (!hasHostel) {
            return const AppEmptyState(
              icon: Icons.error_outline,
              title: 'No Hostel Configured',
              message: 'Please configure a hostel first.',
            );
          }

          return BlocConsumer<DashboardCubit, DashboardState>(
            listenWhen: (previous, current) =>
                previous.status != DashboardOperationStatus.failure &&
                current.status == DashboardOperationStatus.failure &&
                current.summary != null,
            listener: (context, state) {
              if (state.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.errorMessage!)),
                );
              }
            },
            builder: (context, state) {
              if (state.status == DashboardOperationStatus.initial ||
                  (state.status == DashboardOperationStatus.loading &&
                      state.summary == null)) {
                return const Center(child: AppLoadingIndicator());
              }

              if (state.status == DashboardOperationStatus.failure &&
                  state.summary == null) {
                return AppEmptyState(
                  icon: Icons.warning_amber_rounded,
                  title: 'Dashboard Error',
                  message: state.errorMessage ?? 'Unable to load dashboard.',
                  action: ElevatedButton(
                    onPressed: _loadInitialData,
                    child: const Text('Retry'),
                  ),
                );
              }

              final summary = state.summary!;

              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    Text(
                      'Rooms Overview',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildMetricsGrid(
                      context,
                      cards: [
                        DashboardMetricCard(
                          icon: Icons.door_front_door,
                          label: 'Total Rooms',
                          value: summary.totalRooms.toString(),
                          iconColor: AppColors.primary,
                        ),
                        DashboardMetricCard(
                          icon: Icons.check_circle_outline,
                          label: 'Vacant Rooms',
                          value: summary.vacantRooms.toString(),
                          iconColor: AppColors.success,
                        ),
                        DashboardMetricCard(
                          icon: Icons.pie_chart_outline,
                          label: 'Partially Occupied',
                          value: summary.partiallyOccupiedRooms.toString(),
                          iconColor: AppColors.warning,
                        ),
                        DashboardMetricCard(
                          icon: Icons.person_add_alt_1,
                          label: 'Occupied Rooms',
                          value: summary.occupiedRooms.toString(),
                          iconColor: AppColors.error,
                        ),
                        DashboardMetricCard(
                          icon: Icons.block,
                          label: 'Inactive Rooms',
                          value: summary.inactiveRooms.toString(),
                          iconColor: AppColors.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Beds Overview',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildMetricsGrid(
                      context,
                      cards: [
                        DashboardMetricCard(
                          icon: Icons.bed,
                          label: 'Total Beds',
                          value: summary.totalBeds.toString(),
                          iconColor: AppColors.primary,
                        ),
                        DashboardMetricCard(
                          icon: Icons.single_bed,
                          label: 'Vacant Beds',
                          value: summary.vacantBeds.toString(),
                          iconColor: AppColors.success,
                        ),
                        DashboardMetricCard(
                          icon: Icons.hotel,
                          label: 'Occupied Beds',
                          value: summary.occupiedBeds.toString(),
                          iconColor: AppColors.error,
                        ),
                        DashboardMetricCard(
                          icon: Icons.bed_rounded,
                          label: 'Inactive Beds',
                          value: summary.inactiveBeds.toString(),
                          iconColor: AppColors.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DashboardQuickActionCard(
                      icon: Icons.meeting_room,
                      title: 'Manage Rooms',
                      description: 'Add, edit, and manage room capacity.',
                      onTap: _navigateManageRooms,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context,
      {required List<Widget> cards}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        if (constraints.maxWidth < 600) {
          crossAxisCount = 2;
        } else if (constraints.maxWidth < 900) {
          crossAxisCount = 3;
        } else {
          crossAxisCount = 4;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            mainAxisExtent:
                150, // Fixed extent avoids aspect ratio overflow issues
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }
}
