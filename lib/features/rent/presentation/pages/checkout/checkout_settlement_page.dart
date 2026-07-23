// ignore_for_file: use_build_context_synchronously, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_dashboard_ui.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../domain/entities/stay_entity.dart';
import '../../../domain/entities/checkout_request.dart';
import '../../../../tenant/presentation/cubit/tenant_cubit.dart';
import '../../../../room/presentation/cubit/room_cubit.dart';
import '../../../../dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../../../hostel/presentation/cubit/hostel_cubit.dart';
import '../../cubit/checkout/checkout_cubit.dart';
import '../../cubit/checkout/checkout_state.dart';
import '../../cubit/checkout/checkout_summary_cubit.dart';
import '../../cubit/stay/stay_cubit.dart';

class CheckoutSettlementPage extends StatefulWidget {
  final StayEntity stay;

  const CheckoutSettlementPage({
    super.key,
    required this.stay,
  });

  @override
  State<CheckoutSettlementPage> createState() => _CheckoutSettlementPageState();
}

class _CheckoutSettlementPageState extends State<CheckoutSettlementPage> {
  final _damageController = TextEditingController(text: '0.0');
  final _otherChargesController = TextEditingController(text: '0.0');
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  double _damageAmount = 0.0;
  double _otherCharges = 0.0;
  DateTime _checkoutDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CheckoutSummaryCubit>().loadSummary(
              widget.stay.id!,
              checkoutDate: _checkoutDate,
            );
        if (context.read<TenantCubit>().state.tenants.isEmpty) {
          context.read<TenantCubit>().loadTenants();
        }
      }
    });

    _damageController.addListener(() {
      final value = double.tryParse(_damageController.text) ?? 0.0;
      if (value != _damageAmount) {
        setState(() {
          _damageAmount = value;
        });
      }
    });
    _otherChargesController.addListener(() {
      final value = double.tryParse(_otherChargesController.text) ?? 0.0;
      if (value != _otherCharges) {
        setState(() {
          _otherCharges = value;
        });
      }
    });
  }

  @override
  void dispose() {
    _damageController.dispose();
    _otherChargesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  String _monthLabel(int month, int year) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[month - 1]} $year';
  }

  Future<void> _pickCheckoutDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _checkoutDate,
      firstDate: widget.stay.checkInDate,
      lastDate: DateTime(2100),
    );
    if (selectedDate == null || !mounted) return;

    setState(() => _checkoutDate = selectedDate);
    context.read<CheckoutSummaryCubit>().loadSummary(
          widget.stay.id!,
          checkoutDate: selectedDate,
        );
  }

  void _submit(BuildContext context, CheckoutSummaryState summaryState) {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Confirm Checkout'),
        content: const Text(
          'Are you sure you want to complete checkout?\n'
          'This action will release the bed and close the stay.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<CheckoutCubit>().completeCheckout(
                    CheckoutRequest(
                      stayId: widget.stay.id!,
                      damageAmount: _damageAmount,
                      otherCharges: _otherCharges,
                      checkoutDate: _checkoutDate,
                      notes: _notesController.text,
                    ),
                  );
            },
            child: const Text('Complete Checkout'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshPresentationState() async {
    final hostelId = context.read<HostelCubit>().state.hostel?.id;
    final refreshes = <Future<void>>[
      context.read<StayCubit>().loadAllStays(),
      context.read<TenantCubit>().loadTenants(),
    ];

    if (hostelId != null) {
      refreshes.add(context.read<RoomCubit>().loadRooms(hostelId));
      refreshes.add(context.read<DashboardCubit>().loadDashboard(hostelId));
    }

    await Future.wait(refreshes);
  }

  @override
  Widget build(BuildContext context) {
    final now = _checkoutDate;
    return MultiBlocListener(
      listeners: [
        BlocListener<CheckoutCubit, CheckoutState>(
          listener: (context, state) async {
            if (state is CheckoutError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            } else if (state is CheckoutLoaded) {
              await _refreshPresentationState();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Checkout completed successfully.'),
                  backgroundColor: AppColors.success,
                ),
              );
              context.pop(true);
            }
          },
        ),
        BlocListener<CheckoutSummaryCubit, CheckoutSummaryState>(
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error!),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Checkout Settlement'),
        ),
        body: BlocBuilder<CheckoutCubit, CheckoutState>(
          builder: (context, checkoutState) {
            final isSubmitting = checkoutState is CheckoutLoading;

            return BlocBuilder<CheckoutSummaryCubit, CheckoutSummaryState>(
              builder: (context, summaryState) {
                if (summaryState.isLoading) {
                  return const Center(child: AppLoadingIndicator());
                }

                final tenantState = context.watch<TenantCubit>().state;
                final tenantMatches = tenantState.tenants
                    .where((item) => item.id == widget.stay.tenantId)
                    .toList();
                final tenant =
                    tenantMatches.isEmpty ? null : tenantMatches.first;

                // Live settlement calculations (display only — repo re-calculates on save)
                final pendingRent = summaryState.pendingRent;
                final currentMonthCharge = summaryState.currentMonthCharge;
                final depositHeld = summaryState.depositHeld;
                final monthlyRent = summaryState.monthlyRent;

                final currentMonthPaid = summaryState.currentMonthPaid;

                final totalDue = pendingRent +
                    currentMonthCharge -
                    currentMonthPaid +
                    _damageAmount +
                    _otherCharges;
                final netAfterDeposit = depositHeld - totalDue;
                final isRefund = netAfterDeposit >= 0;
                final displayRefund = isRefund ? netAfterDeposit : 0.0;
                final remainingBalance = isRefund ? 0.0 : netAfterDeposit.abs();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. STAY DETAILS
                            AppDashboardCard(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Stay Details',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                    const Divider(),
                                    _InfoRow(
                                      label: 'Tenant',
                                      value: tenant?.fullName ??
                                          'Tenant information unavailable',
                                    ),
                                    _InfoRow(
                                      label: 'Phone',
                                      value: tenant?.phoneNumber ??
                                          'Not available',
                                    ),
                                    _InfoRow(
                                      label: 'Room',
                                      value: 'Room ${widget.stay.roomId}',
                                    ),
                                    _InfoRow(
                                      label: 'Bed',
                                      value: 'Bed ${widget.stay.bedId}',
                                    ),
                                    _InfoRow(
                                      label: 'Check-in',
                                      value:
                                          _formatDate(widget.stay.checkInDate),
                                    ),
                                    InkWell(
                                      onTap: isSubmitting
                                          ? null
                                          : _pickCheckoutDate,
                                      borderRadius: BorderRadius.circular(8),
                                      child: _InfoRow(
                                        label: 'Checkout Date (edit)',
                                        value: _formatDate(_checkoutDate),
                                      ),
                                    ),
                                    _InfoRow(
                                      label: 'Monthly Rent',
                                      value:
                                          '₹${monthlyRent.toStringAsFixed(0)}',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // 2. CURRENT MONTH RENT CARD
                            AppDashboardCard(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer,
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Current Month Rent',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSecondaryContainer,
                                          ),
                                    ),
                                    const Divider(),
                                    _InfoRow(
                                      label:
                                          '1 ${_monthLabel(now.month, now.year)} → ${now.day} ${_monthLabel(now.month, now.year)}',
                                      value:
                                          '₹${currentMonthCharge.toStringAsFixed(0)}',
                                      isBold: true,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Prorated for ${now.day} day${now.day == 1 ? "" : "s"} of ${_monthLabel(now.month, now.year)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSecondaryContainer
                                                .withValues(alpha: 0.7),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // 3. FINANCIAL SUMMARY
                            AppDashboardCard(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Financial Summary',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                    const Divider(),
                                    _InfoRow(
                                      label: 'Monthly Rent',
                                      value:
                                          '₹${monthlyRent.toStringAsFixed(0)}',
                                    ),
                                    _InfoRow(
                                      label: 'Current Month Charge',
                                      value:
                                          '₹${currentMonthCharge.toStringAsFixed(0)}',
                                    ),
                                    _InfoRow(
                                      label: 'Pending Rent (prev. months)',
                                      value:
                                          '₹${pendingRent.toStringAsFixed(0)}',
                                    ),
                                    _InfoRow(
                                      label: 'Already Paid',
                                      value:
                                          '₹${summaryState.alreadyPaid.toStringAsFixed(0)}',
                                    ),
                                    _InfoRow(
                                      label: 'Deposit Held',
                                      value:
                                          '₹${depositHeld.toStringAsFixed(0)}',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // 4. DAMAGE CHARGES
                            AppDashboardCard(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Damage Charges',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                    const Divider(),
                                    AppTextField(
                                      controller: _damageController,
                                      label: 'Damage Amount',
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      enabled: !isSubmitting,
                                      validator: (value) {
                                        if (value == null || value.isEmpty)
                                          return 'Required';
                                        final num = double.tryParse(value);
                                        if (num == null)
                                          return 'Must be a number';
                                        if (num < 0)
                                          return 'Cannot be negative';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    AppTextField(
                                      controller: _otherChargesController,
                                      label: 'Other Charges',
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      enabled: !isSubmitting,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Required';
                                        }
                                        final amount = double.tryParse(value);
                                        if (amount == null)
                                          return 'Must be a number';
                                        if (amount < 0)
                                          return 'Cannot be negative';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    AppTextField(
                                      controller: _notesController,
                                      label: 'Settlement Notes',
                                      maxLines: 3,
                                      enabled: !isSubmitting,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // 5. SETTLEMENT OVERVIEW (live)
                            AppDashboardCard(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Settlement Overview',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer,
                                          ),
                                    ),
                                    const Divider(),
                                    _InfoRow(
                                      label: 'Pending Rent',
                                      value:
                                          '₹${pendingRent.toStringAsFixed(0)}',
                                    ),
                                    _InfoRow(
                                      label: '+ Current Month Charge',
                                      value:
                                          '₹${currentMonthCharge.toStringAsFixed(0)}',
                                    ),
                                    if (currentMonthPaid > 0)
                                      _InfoRow(
                                        label: '- Already Paid (Current Month)',
                                        value:
                                            '₹${currentMonthPaid.toStringAsFixed(0)}',
                                      ),
                                    _InfoRow(
                                      label: '+ Damage Charges',
                                      value:
                                          '₹${_damageAmount.toStringAsFixed(0)}',
                                    ),
                                    const Divider(),
                                    _InfoRow(
                                      label: '= Total Due',
                                      value: '₹${totalDue.toStringAsFixed(0)}',
                                      isBold: true,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    _InfoRow(
                                      label: 'Deposit Held',
                                      value:
                                          '₹${depositHeld.toStringAsFixed(0)}',
                                    ),
                                    _InfoRow(
                                      label: '- Total Due',
                                      value: '₹${totalDue.toStringAsFixed(0)}',
                                    ),
                                    const Divider(),
                                    if (isRefund)
                                      _InfoRow(
                                        label: 'Deposit Refund',
                                        value:
                                            '₹${displayRefund.toStringAsFixed(0)}',
                                        isBold: true,
                                        color: AppColors.success,
                                      )
                                    else
                                      _InfoRow(
                                        label:
                                            'Remaining Balance (tenant owes)',
                                        value:
                                            '₹${remainingBalance.toStringAsFixed(0)}',
                                        isBold: true,
                                        color: AppColors.error,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            // 6. BUTTONS
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed:
                                      isSubmitting ? null : () => context.pop(),
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                AppButton(
                                  label: 'Complete Checkout',
                                  isLoading: isSubmitting,
                                  onPressed: isSubmitting
                                      ? null
                                      : () => _submit(context, summaryState),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? color;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isBold ? FontWeight.bold : null,
                    color: color,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isBold ? FontWeight.bold : null,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}
