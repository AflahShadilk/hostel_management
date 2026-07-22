import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_empty_state.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../../../../core/widgets/app_dashboard_ui.dart';
import '../../../domain/constants/rent_status_constants.dart';
import '../../../domain/entities/payment_entity.dart';
import '../../../domain/entities/rent_collection_item_entity.dart';
import '../../cubit/rent_collection/rent_collection_cubit.dart';
import '../../cubit/rent_collection/rent_collection_state.dart';
import '../../../../../../core/di/injection.dart';
import '../../cubit/payment/payment_cubit.dart';
import '../../cubit/payment/payment_state.dart';


class RentCollectionPage extends StatefulWidget {
  const RentCollectionPage({super.key});

  @override
  State<RentCollectionPage> createState() => _RentCollectionPageState();
}

class _RentCollectionPageState extends State<RentCollectionPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<RentCollectionCubit>().load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RentCollectionCubit, RentCollectionState>(
      listener: (context, state) {
        if (state is RentCollectionError) {
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
          title: const Text('Rent Collection Center'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<RentCollectionCubit>().load(),
            ),
          ],
        ),
        body: BlocBuilder<RentCollectionCubit, RentCollectionState>(
          builder: (context, state) {
            if (state is RentCollectionLoading) {
              return const Center(child: AppLoadingIndicator());
            } else if (state is RentCollectionLoaded) {
              return RefreshIndicator(
                onRefresh: () async =>
                    context.read<RentCollectionCubit>().load(),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildSummaryCards(state),
                            const SizedBox(height: AppSpacing.lg),
                            _buildFiltersAndSearch(context, state),
                          ],
                        ),
                      ),
                    ),
                    if (state.filteredItems.isEmpty)
                      const SliverFillRemaining(
                        child: AppEmptyState(
                          icon: Icons.receipt_long,
                          title: 'No Rent Records Found',
                          message: 'There are no active rent records matching the current filters.',
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.md,
                          right: AppSpacing.md,
                          bottom: AppSpacing.xl,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return _buildRentCollectionCard(
                                  context, state.filteredItems[index]);
                            },
                            childCount: state.filteredItems.length,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }
            return const Center(child: Text('Failed to load data.'));
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCards(RentCollectionLoaded state) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Total Pending',
                amount: state.totalPendingAmount,
                color: AppColors.warning,
                icon: Icons.pending_actions,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _SummaryCard(
                title: 'Overdue Amount',
                amount: state.totalOverdueAmount,
                color: AppColors.error,
                icon: Icons.warning_amber_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Collected (This Month)',
                amount: state.totalCollectedThisMonth,
                color: AppColors.success,
                icon: Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppDashboardCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.receipt,
                              size: 20, color: AppColors.primary),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              'Pending Bills',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '${state.pendingRecordsCount}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ],
                  ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFiltersAndSearch(
      BuildContext context, RentCollectionLoaded state) {
    return Column(
      children: [
        // Search Bar
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search by tenant name, room, or bed...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          ),
          onChanged: (value) =>
              context.read<RentCollectionCubit>().setSearchQuery(value),
        ),
        const SizedBox(height: AppSpacing.md),
        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(context, state, 'All', 'all'),
              const SizedBox(width: AppSpacing.sm),
              _buildFilterChip(context, state, 'Pending', 'pending'),
              const SizedBox(width: AppSpacing.sm),
              _buildFilterChip(context, state, 'Partially Paid', 'partial'),
              const SizedBox(width: AppSpacing.sm),
              _buildFilterChip(context, state, 'Paid', 'paid'),
              const SizedBox(width: AppSpacing.sm),
              _buildFilterChip(context, state, 'Overdue', 'overdue'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Sort Dropdown
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text('Sort by: '),
            DropdownButton<String>(
              value: state.activeSort,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'dueDate', child: Text('Due Date')),
                DropdownMenuItem(
                    value: 'tenantName', child: Text('Tenant Name')),
                DropdownMenuItem(
                    value: 'outstanding', child: Text('Outstanding Amount')),
              ],
              onChanged: (value) {
                if (value != null) {
                  context.read<RentCollectionCubit>().setSort(value);
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(BuildContext context, RentCollectionLoaded state,
      String label, String value) {
    final isSelected = state.activeFilter == value;
    return AppFilterChip(
      label: label,
      selected: isSelected,
      onSelected: (_) => context.read<RentCollectionCubit>().setFilter(value),
    );
  }

  Widget _buildRentCollectionCard(
      BuildContext context, RentCollectionItemEntity item) {
    final r = item.rentRecord;
    final isFullyPaid = r.outstanding <= 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppDashboardCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.tenantName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusChip(context, r.status),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Room ${item.roomNumber} • Bed ${item.bedNumber}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const Divider(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Period',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      Text(
                        r.formattedPeriod,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Due Date',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      Text(
                        _date(r.dueDate),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: r.status == RentStatus.overdue
                                  ? AppColors.error
                                  : null,
                              fontWeight: r.status == RentStatus.overdue
                                  ? FontWeight.bold
                                  : null,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildAmountColumn(
                      context, 'Total Rent', r.amountDue, AppColors.textPrimary),
                ),
                Expanded(
                  child: _buildAmountColumn(
                      context, 'Amount Paid', r.amountPaid, AppColors.success),
                ),
                Expanded(
                  child: _buildAmountColumn(context, 'Outstanding', r.outstanding,
                      r.outstanding > 0 ? AppColors.error : AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Navigate to payment list page filtered by this rent record
                      // Since we reuse existing payment workflows, we can just push payment list
                      // Wait, we don't have a parameter to filter payment list by rent record id out of the box in the route...
                      // Actually we can pass it via extra, or simply push a payment list page instance.
                      // Wait, I am constrained to use the existing routing. Let's see what is allowed.
                      // Usually "Payment Details" means one payment. "Payment History" implies viewing payments for this rent record.
                      // Since there isn't a dedicated "rent payment history" route, I can show a bottom sheet or a dialog with the history!
                      // I'll show a bottom sheet with a basic list of payments, but wait, the instruction says:
                      // "Payment History: Each Rent Record should allow viewing Payment History... Newest payment first."
                      // I will implement a bottom sheet that queries payments for this rentRecord.id.
                      _showPaymentHistory(context, r.id!);
                    },
                    icon: const Icon(Icons.history, size: 18),
                    label: const Text('History'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isFullyPaid
                        ? null
                        : () {
                            // Collect Payment - open add payment page
                            // Create a dummy PaymentEntity with rentRecordId and outstanding amount
                            final dummyPayment = PaymentEntity(
                              rentRecordId: r.id!,
                              stayId: r.stayId,
                              tenantId: item.tenantId,
                              amount: r.outstanding,
                              paymentDate: DateTime.now(),
                              paymentMethod: 'cash', // Default
                              receiptNumber: '', // Default
                              status: 'completed',
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            );
                            context
                                .pushNamed(
                                  AppRoutes.addPaymentName,
                                  extra: dummyPayment,
                                )
                                .then((_) {
                              if (context.mounted) {
                                context.read<RentCollectionCubit>().load();
                              }
                            });
                          },
                    icon: const Icon(Icons.payments_outlined, size: 18),
                    label: const Text('Collect'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentHistory(BuildContext context, int rentRecordId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        // I will use a generic query or existing PaymentCubit to load and filter
        // Wait, PaymentCubit loads all payments. We can just use a local future builder for history!
        // To keep it perfectly clean within Clean Architecture: The standard approach is to use PaymentCubit 
        // to get all payments, but it might be overkill. Let's just create a quick local cubit or future for history,
        // or actually since PaymentCubit is registered as a factory, we can provide it.
        // But let me create a clean stateless widget for it.
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return _PaymentHistorySheet(
                rentRecordId: rentRecordId, scrollController: scrollController);
          },
        );
      },
    );
  }

  Widget _buildAmountColumn(
      BuildContext context, String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    Color color;
    switch (status) {
      case RentStatus.paid:
        color = AppColors.success;
        break;
      case RentStatus.partial:
        color = AppColors.warning;
        break;
      case RentStatus.overdue:
        color = AppColors.error;
        break;
      case RentStatus.pending:
      default:
        color = AppColors.primary;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppDashboardCard(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '₹${amount.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
      ),
    );
  }
}

// Internal widget to show history using existing PaymentCubit logic

class _PaymentHistorySheet extends StatefulWidget {
  final int rentRecordId;
  final ScrollController scrollController;

  const _PaymentHistorySheet(
      {required this.rentRecordId, required this.scrollController});

  @override
  State<_PaymentHistorySheet> createState() => _PaymentHistorySheetState();
}

class _PaymentHistorySheetState extends State<_PaymentHistorySheet> {
  late PaymentCubit _paymentCubit;

  @override
  void initState() {
    super.initState();
    _paymentCubit = getIt<PaymentCubit>()..loadAllPayments();
  }

  @override
  void dispose() {
    _paymentCubit.close();
    super.dispose();
  }

  String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentCubit, PaymentState>(
      bloc: _paymentCubit,
      builder: (context, state) {
        if (state is PaymentLoading) {
          return const Center(child: AppLoadingIndicator());
        } else if (state is PaymentError) {
          return Center(child: Text(state.message));
        } else if (state is PaymentLoaded) {
          final history = state.payments
              .where((p) => p.rentRecordId == widget.rentRecordId)
              .toList()
            ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate)); // Newest first

          if (history.isEmpty) {
            return const Center(
              child: AppEmptyState(
                icon: Icons.history,
                title: 'No Payments',
                message: 'There are no payments for this rent record yet.',
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'Payment History',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final payment = history[index];
                    return AppDashboardCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _date(payment.paymentDate),
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  '₹${payment.amount.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.success,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Method: ${payment.paymentMethod}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (payment.receiptNumber.isNotEmpty)
                                  Text(
                                    'Receipt: ${payment.receiptNumber}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                              ],
                            ),
                            if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Notes: ${payment.notes}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontStyle: FontStyle.italic,
                                    ),
                              ),
                            ]
                          ],
                    ));
                  },
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
