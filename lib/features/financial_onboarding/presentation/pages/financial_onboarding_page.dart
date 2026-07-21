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
        if (state.status == FinancialOnboardingStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
        if (state.status == FinancialOnboardingStatus.success) {
          Navigator.of(context).pop(true);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Financial Onboarding')),
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
                        _SummaryCard(registration: registration),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Security Deposit',
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _depositAmountController,
                                enabled: state.collectDeposit && !saving,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Deposit amount',
                                  prefixText: '\\u{20B9} ',
                                ),
                              ),
                              const SizedBox(height: 12),
                              _PaymentMethodField(
                                value: state.depositPaymentMethod,
                                enabled: state.collectDeposit && !saving,
                                onChanged: context
                                    .read<FinancialOnboardingCubit>()
                                    .setDepositPaymentMethod,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _depositNotesController,
                                enabled: state.collectDeposit && !saving,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Notes',
                                  helperText: 'Optional',
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: saving
                                          ? null
                                          : () => context
                                              .read<FinancialOnboardingCubit>()
                                              .setCollectDeposit(true),
                                      child: const Text('Collect Deposit'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: saving
                                          ? null
                                          : () => context
                                              .read<FinancialOnboardingCubit>()
                                              .setCollectDeposit(false),
                                      child: const Text('Skip'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'First Rent Collection',
                          child: Column(
                            children: [
                              _InfoRow(
                                'Outstanding rent',
                                '\\u{20B9} ${registration.initialRentRecord.outstanding.toStringAsFixed(2)}',
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _rentAmountController,
                                enabled: state.collectRent && !saving,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Amount received',
                                  prefixText: '\\u{20B9} ',
                                  helperText: 'Leave empty or enter 0 for no payment.',
                                ),
                              ),
                              const SizedBox(height: 12),
                              _PaymentMethodField(
                                value: state.rentPaymentMethod,
                                enabled: state.collectRent && !saving,
                                onChanged: context
                                    .read<FinancialOnboardingCubit>()
                                    .setRentPaymentMethod,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _rentNotesController,
                                enabled: state.collectRent && !saving,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Notes',
                                  helperText: 'Optional',
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: saving
                                          ? null
                                          : () => context
                                              .read<FinancialOnboardingCubit>()
                                              .setCollectRent(true),
                                      child: const Text('Collect Rent'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: saving
                                          ? null
                                          : () => context
                                              .read<FinancialOnboardingCubit>()
                                              .setCollectRent(false),
                                      child: const Text('Skip'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: saving ? null : () => _save(context),
                          child: const Text('Save & Finish'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: saving
                              ? null
                              : () => Navigator.of(context).pop(false),
                          child: const Text('Skip For Now'),
                        ),
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

  void _save(BuildContext context) {
    final depositAmount = double.tryParse(_depositAmountController.text.trim()) ?? 0;
    final rentAmount = double.tryParse(_rentAmountController.text.trim()) ?? 0;
    context.read<FinancialOnboardingCubit>().save(
          context: widget.registrationContext,
          depositAmount: depositAmount,
          depositNotes: _depositNotesController.text,
          rentAmount: rentAmount,
          rentNotes: _rentNotesController.text,
        );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.registration});

  final TenantRegistrationContext registration;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _InfoRow('Tenant', registration.tenant.fullName),
            _InfoRow('Room', registration.room.roomNumber),
            _InfoRow('Bed', registration.bed.bedNumber),
            _InfoRow(
              'Monthly rent',
              '\\u{20B9} ${registration.stay.monthlyRentSnapshot.toStringAsFixed(2)}',
            ),
            _InfoRow('Check-in date', _formatDate(registration.stay.checkInDate)),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
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
        decoration: const InputDecoration(labelText: 'Payment method'),
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
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ],
        ),
      );
}

String _formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
