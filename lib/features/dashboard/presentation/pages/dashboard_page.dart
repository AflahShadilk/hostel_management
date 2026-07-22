import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_dashboard_ui.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../hostel/presentation/cubit/hostel_cubit.dart';
import '../../domain/entities/dashboard_activity_entity.dart';
import '../../domain/entities/recent_stay_item_entity.dart';
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
    final authState   = context.watch<AuthCubit>().state;
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
            onPressed: () => context.read<AuthCubit>().logout(),
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
                listener: (context, state) => _refresh(),
              ),
            ],
            child: BlocBuilder<DashboardCubit, DashboardState>(
              builder: (context, state) {
                // Full-screen loading on first load
                if (state.status == DashboardOperationStatus.initial ||
                    (state.status == DashboardOperationStatus.loading && state.summary == null)) {
                  return const Center(child: AppLoadingIndicator());
                }

                // Full-screen error when no cached data is available
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
                final theme   = Theme.of(context);
                // ignore: unnecessary_string_escapes
                const rupee = '\u20B9';

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.xl,
                    ),
                    children: [
                      // ── 1. Occupancy KPI Grid ────────────────────────────
                      _sectionTitle(theme, 'Occupancy'),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = constraints.maxWidth < 600 ? 2 : 4;
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
                                label: 'Total Rooms',
                                value: summary.totalRooms.toString(),
                                iconColor: theme.colorScheme.primary,
                              ),
                              DashboardMetricCard(
                                icon: Icons.bed_rounded,
                                label: 'Total Beds',
                                value: summary.totalBeds.toString(),
                                iconColor: theme.colorScheme.primary,
                              ),
                              DashboardMetricCard(
                                icon: Icons.hotel_rounded,
                                label: 'Occupied Beds',
                                value: summary.occupiedBeds.toString(),
                                iconColor: theme.colorScheme.tertiary,
                              ),
                              DashboardMetricCard(
                                icon: Icons.king_bed_outlined,
                                label: 'Vacant Beds',
                                value: summary.vacantBeds.toString(),
                                iconColor: theme.colorScheme.secondary,
                              ),
                              DashboardMetricCard(
                                icon: Icons.groups_rounded,
                                label: 'Active Tenants',
                                value: summary.activeTenants.toString(),
                                iconColor: theme.colorScheme.secondary,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // ── 2. Financial KPI Grid ────────────────────────────
                      _sectionTitle(theme, 'Financials (This Month)'),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = constraints.maxWidth < 600 ? 2 : 4;
                          return GridView.count(
                            crossAxisCount: crossAxisCount,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.0,
                            children: [
                              DashboardMetricCard(
                                icon: Icons.payments_rounded,
                                label: 'Rent Collected',
                                value: '$rupee${summary.monthlyRentCollected.toStringAsFixed(0)}',
                                iconColor: Colors.green,
                              ),
                              DashboardMetricCard(
                                icon: Icons.pending_actions_rounded,
                                label: 'Pending Rent',
                                value: '$rupee${summary.pendingRent.toStringAsFixed(0)}',
                                iconColor: theme.colorScheme.error,
                              ),
                              DashboardMetricCard(
                                icon: Icons.receipt_long_rounded,
                                label: 'Expenses',
                                value: '$rupee${summary.monthlyExpenses.toStringAsFixed(0)}',
                                iconColor: Colors.orange,
                              ),
                              DashboardMetricCard(
                                icon: Icons.trending_up_rounded,
                                label: 'Profit',
                                value: '$rupee${summary.monthlyProfit.toStringAsFixed(0)}',
                                iconColor: summary.monthlyProfit >= 0 ? Colors.green : theme.colorScheme.error,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // ── 3. Attention Required ────────────────────────────
                      _sectionTitle(theme, 'Attention Required'),
                      const SizedBox(height: 12),
                      if (summary.vacantBeds == 0 && summary.todayCheckouts == 0 && summary.pendingRent == 0)
                        _attentionContainer(
                          theme,
                          color: theme.colorScheme.surfaceContainer,
                          borderColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle_outline_rounded, color: Colors.green),
                              SizedBox(width: 16),
                              Expanded(child: Text('No pending actions. You are all caught up!')),
                            ],
                          ),
                        )
                      else
                        _attentionContainer(
                          theme,
                          color: theme.colorScheme.errorContainer.withValues(alpha: 0.6),
                          borderColor: theme.colorScheme.error.withValues(alpha: 0.3),
                          child: Column(
                            children: [
                              if (summary.vacantBeds > 0)
                                _buildActionRow(
                                  context,
                                  Icons.warning_amber_rounded,
                                  '${summary.vacantBeds} beds are currently vacant',
                                  'Fill them up to maximize revenue.',
                                  theme.colorScheme.error,
                                ),
                              if (summary.todayCheckouts > 0) ...[
                                if (summary.vacantBeds > 0) const Divider(height: 24),
                                _buildActionRow(
                                  context,
                                  Icons.event_busy_rounded,
                                  '${summary.todayCheckouts} tenants checking out today',
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
                                  '$rupee${summary.pendingRent.toStringAsFixed(2)} in pending rent',
                                  'Follow up on outstanding payments.',
                                  theme.colorScheme.error,
                                ),
                              ],
                            ],
                          ),
                        ),
                      const SizedBox(height: AppSpacing.lg),

                      // ── 4. Quick Actions ─────────────────────────────────
                      _sectionTitle(theme, 'Quick Actions'),
                      const SizedBox(height: 12),
                      DashboardQuickActionCard(
                        icon: Icons.meeting_room_rounded,
                        title: 'Manage Rooms',
                        description: 'Add or edit rooms, update capacities and statuses.',
                        onTap: () => StatefulNavigationShell.of(context).goBranch(2),
                      ),
                      const SizedBox(height: 12),
                      DashboardQuickActionCard(
                        icon: Icons.person_add_alt_1_rounded,
                        title: 'Manage Tenants',
                        description: 'Register new tenants, manage stays, and handle check-outs.',
                        onTap: () => StatefulNavigationShell.of(context).goBranch(3),
                      ),
                      const SizedBox(height: 12),
                      DashboardQuickActionCard(
                        icon: Icons.payments_rounded,
                        title: 'Collect Rent',
                        description: 'Record rent payments and manage rent records.',
                        onTap: () => StatefulNavigationShell.of(context).goBranch(10),
                      ),
                      const SizedBox(height: 12),
                      DashboardQuickActionCard(
                        icon: Icons.account_balance_rounded,
                        title: 'Add Expense',
                        description: 'Log new hostel expenses and manage categories.',
                        onTap: () => StatefulNavigationShell.of(context).goBranch(11),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // ── 5. Recent Check-ins ──────────────────────────────
                      _sectionTitle(theme, 'Recent Check-ins'),
                      const SizedBox(height: 12),
                      _buildRecentStayList(theme, summary.recentCheckIns, isCheckIn: true),
                      const SizedBox(height: AppSpacing.lg),

                      // ── 6. Recent Check-outs ─────────────────────────────
                      _sectionTitle(theme, 'Recent Checkouts'),
                      const SizedBox(height: 12),
                      _buildRecentStayList(theme, summary.recentCheckOuts, isCheckIn: false),
                      const SizedBox(height: AppSpacing.lg),

                      // ── 7. Recent Activity ───────────────────────────────
                      _sectionTitle(theme, 'Recent Activity'),
                      const SizedBox(height: 12),
                      _buildRecentActivityList(theme, summary.recentActivities),
                      const SizedBox(height: AppSpacing.xl),
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

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _sectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  Widget _attentionContainer(ThemeData theme, {required Color color, required Color borderColor, required Widget child}) {
    return AppDashboardCard(
      backgroundColor: color,
      borderColor: borderColor,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: child,
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
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentStayList(ThemeData theme, List<RecentStayItemEntity> items, {required bool isCheckIn}) {
    if (items.isEmpty) {
      return AppDashboardCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        backgroundColor: theme.colorScheme.surfaceContainer,
        child: Center(
          child: Text(isCheckIn ? 'No recent check-ins' : 'No recent checkouts', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
      );
    }

    return AppDashboardCard(
      backgroundColor: theme.colorScheme.surfaceContainer,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: items.length,
        separatorBuilder: (_, __) => Divider(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3), height: 1, indent: 64, endIndent: 16),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                isCheckIn ? Icons.login_rounded : Icons.logout_rounded,
                color: theme.colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            title: Text(item.tenantName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text('${item.roomNumber} · ${item.bedNumber}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            trailing: Text(_formatDate(item.date), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          );
        },
      ),
    );
  }

  Widget _buildRecentActivityList(ThemeData theme, List<DashboardActivityEntity> activities) {
    if (activities.isEmpty) {
      return AppDashboardCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        backgroundColor: theme.colorScheme.surfaceContainer,
        child: const Center(child: Text('No recent activity.')),
      );
    }

    return AppDashboardCard(
      backgroundColor: theme.colorScheme.surfaceContainer,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: activities.length,
        separatorBuilder: (_, __) => Divider(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3), height: 1, indent: 64, endIndent: 16),
        itemBuilder: (context, index) {
          final activity = activities[index];
          final iconData = switch (activity.type) {
            DashboardActivityType.tenantCheckIn  => Icons.login_rounded,
            DashboardActivityType.tenantCheckOut => Icons.logout_rounded,
            DashboardActivityType.rentCollected  => Icons.payments_rounded,
            DashboardActivityType.roomAdded      => Icons.meeting_room_rounded,
            DashboardActivityType.expenseAdded   => Icons.account_balance_rounded,
            DashboardActivityType.other          => Icons.info_outline_rounded,
          };
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(iconData, color: theme.colorScheme.onPrimaryContainer, size: 20),
            ),
            title: Text(activity.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
            subtitle: Text(activity.subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            trailing: Text(_formatTimeAgo(activity.time), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 1)    return '${diff.inDays} days ago';
    if (diff.inDays == 1)   return 'Yesterday';
    if (diff.inHours > 1)   return '${diff.inHours} hours ago';
    if (diff.inHours == 1)  return '1 hour ago';
    if (diff.inMinutes > 1) return '${diff.inMinutes} mins ago';
    if (diff.inMinutes == 1)return '1 minute ago';
    return 'Just now';
  }
}
