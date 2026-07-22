import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../cubit/tenant_history_cubit.dart';

class TenantHistoryPage extends StatefulWidget {
  const TenantHistoryPage({super.key});

  @override
  State<TenantHistoryPage> createState() => _TenantHistoryPageState();
}

class _TenantHistoryPageState extends State<TenantHistoryPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<TenantHistoryCubit>().loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    context.read<TenantHistoryCubit>().setSearchQuery(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tenant History'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(116),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                _buildSearchBar(),
                const SizedBox(height: 8),
                _buildFiltersRow(),
              ],
            ),
          ),
        ),
      ),
      body: BlocBuilder<TenantHistoryCubit, TenantHistoryState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const AppLoadingIndicator();
          }

          if (state.error != null) {
            return Center(child: Text(state.error!));
          }

          if (state.stays.isEmpty) {
            return const AppEmptyState(
              icon: Icons.history,
              title: 'No History Found',
              message: 'No completed stays found.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<TenantHistoryCubit>().loadHistory(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.stays.length,
              itemBuilder: (context, index) {
                final stay = state.stays[index];
                return _TenantHistoryCard(
                  stay: stay,
                  onTap: () {
                    context.goNamed(
                      AppRoutes.historyDetailsName,
                      pathParameters: {'stayId': stay.stayId.toString()},
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search by name, phone, room...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
      ),
      onChanged: _onSearchChanged,
    );
  }

  Widget _buildFiltersRow() {
    return BlocBuilder<TenantHistoryCubit, TenantHistoryState>(
      builder: (context, state) {
        return Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<HistoryFilter>(
                value: state.filter,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: HistoryFilter.all, child: Text('All Time')),
                  DropdownMenuItem(value: HistoryFilter.thisMonth, child: Text('This Month')),
                  DropdownMenuItem(value: HistoryFilter.lastMonth, child: Text('Last Month')),
                  DropdownMenuItem(value: HistoryFilter.currentYear, child: Text('This Year')),
                ],
                onChanged: (val) {
                  if (val != null) context.read<TenantHistoryCubit>().setFilter(val);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<HistorySort>(
                value: state.sort,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: HistorySort.newestCheckout, child: Text('Newest First')),
                  DropdownMenuItem(value: HistorySort.oldestCheckout, child: Text('Oldest First')),
                  DropdownMenuItem(value: HistorySort.tenantName, child: Text('Name (A-Z)')),
                ],
                onChanged: (val) {
                  if (val != null) context.read<TenantHistoryCubit>().setSort(val);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TenantHistoryCard extends StatelessWidget {
  final dynamic stay; // TenantHistorySummary
  final VoidCallback onTap;

  const _TenantHistoryCard({required this.stay, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      stay.tenantName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Completed',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onTertiaryContainer,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(stay.phoneNumber, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(width: 16),
                  Icon(Icons.badge, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('ID: ${stay.tenantId}', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.door_front_door, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('Room ${stay.roomId} • Bed ${stay.bedId}', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoColumn(label: 'Total Stay', value: '${stay.totalStayDays} days', context: context),
                  _InfoColumn(label: 'Total Billed', value: '₹${stay.totalRentCharged.toInt()}', context: context),
                  _InfoColumn(label: 'Total Paid', value: '₹${stay.totalPaid.toInt()}', context: context),
                  _InfoColumn(
                    label: 'Deposit Refund',
                    value: '₹${stay.depositRefunded.toInt()}',
                    context: context,
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

class _InfoColumn extends StatelessWidget {
  final String label;
  final String value;
  final BuildContext context;

  const _InfoColumn({required this.label, required this.value, required this.context});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
