import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../rent/domain/constants/rent_status_constants.dart';
import '../../../tenant/domain/entities/tenant_registration_context.dart';
import '../cubit/financial_onboarding_cubit.dart';
import '../cubit/financial_onboarding_state.dart';

class FinancialOnboardingPage extends StatefulWidget {
  const FinancialOnboardingPage({required this.registrationContext, super.key});

  final TenantRegistrationContext registrationContext;

  @override
  State<FinancialOnboardingPage> createState() =>
      _FinancialOnboardingPageState();
}

class _FinancialOnboardingPageState extends State<FinancialOnboardingPage> {
  final _depositAmountController = TextEditingController();
  final _depositNotesController = TextEditingController();
  final _rentAmountController = TextEditingController();
  final _rentNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<FinancialOnboardingCubit>().init(widget.registrationContext);

    _rentAmountController.addListener(() {
      context
          .read<FinancialOnboardingCubit>()
          .rentReceivedChanged(_rentAmountController.text);
    });
  }

  @override
  void dispose() {
    _depositAmountController.dispose();
    _depositNotesController.dispose();
    _rentAmountController.dispose();
    _rentNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final registration = widget.registrationContext;
    return BlocListener<FinancialOnboardingCubit, FinancialOnboardingState>(
      listener: (context, state) {
        // A validation or platform error occurred — show the message.
        if (state.status == FinancialOnboardingStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }

        // A single section was saved — stay on page, show confirmation.
        if (state.status == FinancialOnboardingStatus.stepSaved) {
          final label = state.depositDone && !state.rentDone
              ? 'Deposit saved ✔'
              : state.rentDone && !state.depositDone
                  ? 'Rent saved ✔'
                  : 'Section saved ✔';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(label),
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Both sections are resolved — the ONLY moment we navigate away.
        if (state.status == FinancialOnboardingStatus.completed) {
          Navigator.of(context).pop(true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Financial Onboarding'),
          centerTitle: true,
        ),
        body: BlocBuilder<FinancialOnboardingCubit, FinancialOnboardingState>(
          builder: (context, state) {
            final saving = state.status == FinancialOnboardingStatus.saving;
            return SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: ListView(
                      padding: EdgeInsets.all(
                        constraints.maxWidth >= 600 ? 32 : 16,
                      ),
                      children: [
                        if (saving) const LinearProgressIndicator(),
                        if (saving) const SizedBox(height: 16),
                        _SummaryCard(registration: registration, state: state),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Security Deposit',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _depositAmountController,
                                enabled: !saving,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Deposit Amount',
                                  prefixText: '₹ ',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _PaymentMethodField(
                                value: state.depositPaymentMethod ??
                                    PaymentMethod.cash,
                                enabled: !saving,
                                onChanged: context
                                    .read<FinancialOnboardingCubit>()
                                    .setDepositPaymentMethod,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _depositNotesController,
                                enabled: !saving,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Notes',
                                  helperText: 'Optional',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 8),
                              FilledButton.icon(
                                onPressed: saving || state.depositDone
                                    ? null
                                    : () => _saveDeposit(context),
                                icon: state.depositDone
                                    ? const Icon(Icons.check_circle_outline)
                                    : const Icon(Icons.shield_outlined),
                                label: Text(
                                  state.depositDone
                                      ? 'Deposit Collected'
                                      : 'Collect Deposit',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'First Rent',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _rentAmountController,
                                enabled: !saving,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Received Amount',
                                  prefixText: '₹ ',
                                  helperText:
                                      'Leave empty or enter 0 for no payment.',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _PaymentMethodField(
                                value: state.rentPaymentMethod ??
                                    PaymentMethod.cash,
                                enabled: !saving,
                                onChanged: context
                                    .read<FinancialOnboardingCubit>()
                                    .setRentPaymentMethod,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _rentNotesController,
                                enabled: !saving,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Notes',
                                  helperText: 'Optional',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 8),
                              FilledButton.icon(
                                onPressed: saving || state.rentDone
                                    ? null
                                    : () => _saveRent(context),
                                icon: state.rentDone
                                    ? const Icon(Icons.check_circle_outline)
                                    : const Icon(Icons.payments_outlined),
                                label: Text(
                                  state.rentDone
                                      ? 'Rent Collected'
                                      : 'Collect Rent',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: saving
                                    ? null
                                    : () => context
                                        .read<FinancialOnboardingCubit>()
                                        .skipAndFinish(),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Text('Skip For Now'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: FilledButton(
                                onPressed:
                                    saving ? null : () => _finish(context),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Text('Save & Finish'),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _saveDeposit(BuildContext context) {
    final depositAmount =
        double.tryParse(_depositAmountController.text.trim()) ?? 0;
    context.read<FinancialOnboardingCubit>().saveSection(
          context: widget.registrationContext,
          depositAmount: depositAmount,
          depositNotes: _depositNotesController.text,
          rentAmount: 0,
          rentNotes: '',
          processDeposit: true,
          processRent: false,
        );
  }

  void _saveRent(BuildContext context) {
    final rentAmount = double.tryParse(_rentAmountController.text.trim()) ?? 0;
    context.read<FinancialOnboardingCubit>().saveSection(
          context: widget.registrationContext,
          depositAmount: 0,
          depositNotes: '',
          rentAmount: rentAmount,
          rentNotes: _rentNotesController.text,
          processDeposit: false,
          processRent: true,
        );
  }

  /// Called by both "Skip For Now" and "Save & Finish".
  ///
  /// The cubit's [finish] method handles any remaining unsaved sections
  /// (including zero-amount skips) and then emits [completed] to navigate away.
  void _finish(BuildContext context) {
    final depositAmount =
        double.tryParse(_depositAmountController.text.trim()) ?? 0;
    final rentAmount = double.tryParse(_rentAmountController.text.trim()) ?? 0;
    context.read<FinancialOnboardingCubit>().finish(
          context: widget.registrationContext,
          depositAmount: depositAmount,
          depositNotes: _depositNotesController.text,
          rentAmount: rentAmount,
          rentNotes: _rentNotesController.text,
        );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.registration, required this.state});

  final TenantRegistrationContext registration;
  final FinancialOnboardingState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _InfoRow('👤 Tenant', registration.tenant.fullName, isBold: true),
            const SizedBox(height: 8),
            _InfoRow('🏠 Room',
                '${registration.room.roomNumber} • ${registration.bed.bedNumber}'),
            const SizedBox(height: 8),
            _InfoRow('📅 Check-in', _formatDate(registration.stay.checkInDate)),
            const SizedBox(height: 8),
            _InfoRow(
              '💰 Monthly Rent',
              '₹${registration.stay.monthlyRentSnapshot.toStringAsFixed(0)}',
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _InfoRow(
              'First Month Rent',
              '₹${state.firstMonthRent.toStringAsFixed(0)}',
              isBold: true,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              'Outstanding',
              '₹${state.outstandingAmount.toStringAsFixed(0)}',
              isBold: true,
              valueColor: theme.colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 24),
              child,
            ],
          ),
        ),
      );
}

class _PaymentMethodField extends StatelessWidget {
  const _PaymentMethodField({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String? value;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
        value: value,
        decoration: const InputDecoration(
          labelText: 'Payment Method',
          border: OutlineInputBorder(),
        ),
        items: const [
          DropdownMenuItem(value: PaymentMethod.cash, child: Text('Cash')),
          DropdownMenuItem(value: PaymentMethod.upi, child: Text('UPI')),
          DropdownMenuItem(
            value: PaymentMethod.bankTransfer,
            child: Text('Bank Transfer'),
          ),
          DropdownMenuItem(value: PaymentMethod.other, child: Text('Other')),
        ],
        onChanged: enabled ? onChanged : null,
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value,
      {this.isBold = false, this.valueColor});

  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = isBold
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        : theme.textTheme.bodyLarge;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textStyle?.copyWith(
            color: isBold
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: textStyle?.copyWith(
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

String _formatDate(DateTime value) {
  const monthNames = [
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
    'Dec'
  ];
  final day = value.day.toString().padLeft(2, '0');
  final month = monthNames[value.month - 1];
  final year = value.year;
  return '$day $month $year';
}
