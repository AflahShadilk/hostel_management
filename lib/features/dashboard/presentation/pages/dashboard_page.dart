import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../hostel/presentation/cubit/hostel_cubit.dart';
import '../../domain/entities/dashboard_activity_entity.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_operation_status.dart';
import '../cubit/dashboard_state.dart';
import '../../../tenant/presentation/cubit/tenant_cubit.dart';
import '../../../tenant/presentation/cubit/tenant_state.dart';
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
    if (hostelState.hostel?.id != null) {
      context.read<DashboardCubit>().loadDashboard(hostelState.hostel!.id!);
    }
  }

  Future<void> _refresh() async {
    final hostelState = context.read<HostelCubit>().state;
    if (hostelState.hostel?.id != null) {
      await context.read<DashboardCubit>().refreshDashboard(hostelState.hostel!.id!);
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(hostelName),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
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
              message: 'Hostel access for manager accounts will be available after manager assignment is configured.',
            );
          }

          if (!hasHostel) {
            return const AppEmptyState(
              icon: Icons.error_outline,
              title: 'No Hostel Configured',
              message: 'Please configure a hostel first.',
            );
          }

          return MultiBlocListener(
            listeners: [
              BlocListener<DashboardCubit, DashboardState>(
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
              ),
              BlocListener<TenantCubit, TenantState>(
                listenWhen: (previous, current) =>
                    previous.status != TenantOperationStatus.loaded &&
                    current.status == TenantOperationStatus.loaded,
                listener: (context, state) {
                  _refresh();
                },
              ),
            ],
            child: BlocBuilder<DashboardCubit, DashboardState>(
              builder: (context, state) {
                if (state.status == DashboardOperationStatus.initial ||
                    (state.status == DashboardOperationStatus.loading && state.summary == null)) {
                  return const Center(child: AppLoadingIndicator());
                }

                if (state.status == DashboardOperationStatus.failure && state.summary == null) {
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
                final theme = Theme.of(context);

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    children: [
                      // 1. KPI Cards Section
                      LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = constraints.maxWidth < 600 ? 2 : 4;
                          return GridView.count(
                            crossAxisCount: crossAxisCount,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.0,
                            children: [
                              DashboardMetricCard(
                                icon: Icons.door_front_door_rounded,
                                label: 'Available Rooms',
                                value: summary.vacantRooms.toString(),
                                iconColor: theme.colorScheme.primary,
                              ),
                              DashboardMetricCard(
                                icon: Icons.hotel_rounded,
                                label: 'Occupied Beds',
                                value: summary.occupiedBeds.toString(),
                                iconColor: theme.colorScheme.tertiary,
                              ),
                              DashboardMetricCard(
                                icon: Icons.groups_rounded,
                                label: 'Active Tenants',
                                value: summary.activeTenants.toString(),
                                iconColor: theme.colorScheme.secondary,
                              ),
                              DashboardMetricCard(
                                icon: Icons.payments_rounded,
                                label: 'Pending Rent',
                                // ignore: unnecessary_string_escapes
                                value: '\₹${summary.pendingRent.toStringAsFixed(2)}',
                                iconColor: theme.colorScheme.error,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // 2. Pending Actions (Attention) Section
                      Text(
                        'Attention Required',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (summary.vacantBeds == 0 && summary.todayCheckouts == 0 && summary.pendingRent == 0)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.fromBorderSide(
                              BorderSide(
                                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle_outline_rounded, color: Colors.green),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text('No pending actions. You are all caught up!'),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.fromBorderSide(
                              BorderSide(
                                color: theme.colorScheme.error.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              if (summary.vacantBeds > 0) ...[
                                _buildActionRow(
                                  context,
                                  Icons.warning_amber_rounded,
                                  '${summary.vacantBeds} beds are currently vacant',
                                  'Fill them up to maximize revenue.',
                                  theme.colorScheme.error,
                                ),
                              ],
                              if (summary.todayCheckouts > 0) ...[
                                if (summary.vacantBeds > 0) const Divider(height: 24),
                                _buildActionRow(
                                  context,
                                  Icons.event_busy_rounded,
                                  '${summary.todayCheckouts} Tenants checking out today',
                                  'Ensure checkout procedures are completed.',
                                  theme.colorScheme.error,
                                ),
                              ],
                              if (summary.pendingRent > 0) ...[
                                if (summary.vacantBeds > 0 || summary.todayCheckouts > 0) const Divider(height: 24),
                                _buildActionRow(
                                  context,
                                  Icons.account_balance_wallet_rounded,
                                  // ignore: unnecessary_string_escapes
                                  '\₹${summary.pendingRent.toStringAsFixed(2)} in pending rent',
                                  'Follow up on outstanding payments.',
                                  theme.colorScheme.error,
                                ),
                              ],
                            ],
                          ),
                        ),
                      const SizedBox(height: 32),

                      // 3. Quick Actions Section
                      Text(
                        'Quick Actions',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DashboardQuickActionCard(
                        icon: Icons.meeting_room_rounded,
                        title: 'Manage Rooms',
                        description: 'Add or edit rooms, update capacities and statuses.',
                        onTap: () {
                          StatefulNavigationShell.of(context).goBranch(2);
                        },
                      ),
                      const SizedBox(height: 16),
                      DashboardQuickActionCard(
                        icon: Icons.person_add_alt_1_rounded,
                        title: 'Manage Tenants',
                        description: 'Register new tenants, manage stays, and handle check-outs.',
                        onTap: () {
                          StatefulNavigationShell.of(context).goBranch(3);
                        },
                      ),
                      const SizedBox(height: 16),
                      DashboardQuickActionCard(
                        icon: Icons.payments_rounded,
                        title: 'Collect Rent',
                        description: 'Record rent payments and manage rent records.',
                        onTap: () {
                          StatefulNavigationShell.of(context).goBranch(10);
                        },
                      ),
                      const SizedBox(height: 16),
                      DashboardQuickActionCard(
                        icon: Icons.account_balance_rounded,
                        title: 'Add Expense',
                        description: 'Log new hostel expenses and manage categories.',
                        onTap: () {
                          StatefulNavigationShell.of(context).goBranch(11);
                        },
                      ),
                      const SizedBox(height: 32),

                      // 4. Recent Activity Section
                      Text(
                        'Recent Activity',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildRecentActivityList(theme, summary.recentActivities),
                      const SizedBox(height: 80), // Padding for floating bottom bar
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionRow(BuildContext context, IconData icon, String title, String subtitle, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivityList(ThemeData theme, List<DashboardActivityEntity> activities) {
    if (activities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.fromBorderSide(
            BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: const Center(
          child: Text('No recent activity.'),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.fromBorderSide(
          BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(8),
        itemCount: activities.length,
        separatorBuilder: (context, index) => Divider(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          height: 1,
          indent: 64,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          final activity = activities[index];
          IconData iconData;
          switch (activity.type) {
            case DashboardActivityType.tenantCheckIn:
              iconData = Icons.login_rounded;
              break;
            case DashboardActivityType.tenantCheckOut:
              iconData = Icons.logout_rounded;
              break;
            case DashboardActivityType.rentCollected:
              iconData = Icons.payments_rounded;
              break;
            case DashboardActivityType.roomAdded:
              iconData = Icons.meeting_room_rounded;
              break;
            case DashboardActivityType.expenseAdded:
              iconData = Icons.account_balance_rounded;
              break;
            case DashboardActivityType.other:
              iconData = Icons.info_outline_rounded;
              break;
          }

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                iconData,
                color: theme.colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            title: Text(
              activity.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              activity.subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Text(
              _formatTimeAgo(activity.time),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTimeAgo(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inDays > 0) {
      if (difference.inDays == 1) return 'Yesterday';
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      if (difference.inHours == 1) return '1 hour ago';
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      if (difference.inMinutes == 1) return '1 minute ago';
      return '${difference.inMinutes} mins ago';
    } else {
      return 'Just now';
    }
  }
}
