import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../domain/entities/stay_entity.dart';
import '../../../domain/entities/checkout_request.dart';
import '../../cubit/checkout/checkout_cubit.dart';
import '../../cubit/checkout/checkout_state.dart';
import '../../cubit/checkout/checkout_summary_cubit.dart';

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
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  double _damageAmount = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CheckoutSummaryCubit>().loadSummary(widget.stay.id!);
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
  }

  @override
  void dispose() {
    _damageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CheckoutCubit, CheckoutState>(
          listener: (context, state) {
            if (state is CheckoutError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            } else if (state is CheckoutLoaded) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Checkout completed successfully.'),
                  backgroundColor: AppColors.success,
                ),
              );
              // Navigate back
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

                // Live calculations
                final outstandingRent = summaryState.outstandingRent;
                final depositHeld = summaryState.depositHeld;
                
                final totalDue = outstandingRent + _damageAmount;
                final refund = depositHeld - totalDue;
                final isNegativeRefund = refund < 0;
                
                final displayRefund = isNegativeRefund ? 0.0 : refund;
                final remainingBalance = isNegativeRefund ? refund.abs() : 0.0;

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
                            // 1. Read-only section
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Stay Details', style: Theme.of(context).textTheme.titleLarge),
                                    const Divider(),
                                    _InfoRow(label: 'Tenant Name', value: 'Tenant #${widget.stay.tenantId}'),
                                    _InfoRow(label: 'Room Number', value: 'Room ${widget.stay.roomId}'),
                                    _InfoRow(label: 'Bed Number', value: 'Bed ${widget.stay.bedId}'),
                                    _InfoRow(label: 'Check-in Date', value: _formatDate(widget.stay.checkInDate)),
                                    _InfoRow(label: 'Checkout Date', value: _formatDate(DateTime.now())),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            
                            // 2. FINANCIAL SUMMARY
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Financial Summary', style: Theme.of(context).textTheme.titleLarge),
                                    const Divider(),
                                    _InfoRow(label: 'Outstanding Rent', value: outstandingRent.toStringAsFixed(2)),
                                    _InfoRow(label: 'Deposit Held', value: depositHeld.toStringAsFixed(2)),
                                    _InfoRow(label: 'Already Paid', value: summaryState.alreadyPaid.toStringAsFixed(2)),
                                    _InfoRow(label: 'Current Balance', value: (outstandingRent - depositHeld).toStringAsFixed(2)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // 3. DAMAGE CHARGES
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Damage Charges', style: Theme.of(context).textTheme.titleLarge),
                                    const Divider(),
                                    AppTextField(
                                      controller: _damageController,
                                      label: 'Damage Amount',
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      enabled: !isSubmitting,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return 'Required';
                                        final num = double.tryParse(value);
                                        if (num == null) return 'Must be a number';
                                        if (num < 0) return 'Cannot be negative';
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

                            // 4. SUMMARY CARD (Live Calculation)
                            Card(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Settlement Overview', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer)),
                                    const Divider(),
                                    _InfoRow(label: 'Outstanding Rent', value: outstandingRent.toStringAsFixed(2)),
                                    _InfoRow(label: '+ Damage Charges', value: _damageAmount.toStringAsFixed(2)),
                                    const Divider(),
                                    _InfoRow(label: '= Total Due', value: totalDue.toStringAsFixed(2), isBold: true),
                                    const SizedBox(height: AppSpacing.sm),
                                    _InfoRow(label: 'Deposit Held', value: depositHeld.toStringAsFixed(2)),
                                    _InfoRow(label: '- Total Due', value: totalDue.toStringAsFixed(2)),
                                    const Divider(),
                                    if (isNegativeRefund)
                                      _InfoRow(label: 'Remaining Balance', value: remainingBalance.toStringAsFixed(2), isBold: true, color: AppColors.error)
                                    else
                                      _InfoRow(label: 'Refund', value: displayRefund.toStringAsFixed(2), isBold: true, color: AppColors.success),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            // 5. BUTTONS
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: isSubmitting ? null : () => context.pop(),
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                AppButton(
                                  label: 'Complete Checkout',
                                  isLoading: isSubmitting,
                                  onPressed: isSubmitting ? null : () => _submit(context, summaryState),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }
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
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : null,
              color: color,
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
