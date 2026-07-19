// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../domain/entities/deposit_entity.dart';
import '../../cubit/deposit/deposit_cubit.dart';
import '../../cubit/deposit/deposit_state.dart';
import '../../cubit/ui/selected_date_cubit.dart';
import '../../cubit/ui/selected_status_cubit.dart';
import '../../cubit/ui/submitting_cubit.dart';

class AddEditDepositPage extends StatefulWidget {
  final DepositEntity? deposit;
  const AddEditDepositPage({super.key, this.deposit});
  @override
  State<AddEditDepositPage> createState() => _AddEditDepositPageState();
}

class _AddEditDepositPageState extends State<AddEditDepositPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _stayId;
  late final TextEditingController _amount;
  late final TextEditingController _refundedAmount;
  bool get _editing => widget.deposit != null;

  @override
  void initState() {
    super.initState();
    final deposit = widget.deposit;
    _stayId =
        TextEditingController(text: deposit?.stayId.toString() ?? '');
    _amount =
        TextEditingController(text: deposit?.amount.toString() ?? '');
    _refundedAmount =
        TextEditingController(text: deposit?.refundedAmount.toString() ?? '');
  }

  @override
  void dispose() {
    _stayId.dispose();
    _amount.dispose();
    _refundedAmount.dispose();
    super.dispose();
  }

  String _date(DateTime? value) => value == null
      ? 'Select date'
      : '${value.day.toString().padLeft(2, '0')}/'
          '${value.month.toString().padLeft(2, '0')}/${value.year}';

  Future<void> _pickDate(BuildContext context, bool refund) async {
    final receivedCubit = context.read<_ReceivedDateCubit>();
    final refundCubit = context.read<_RefundDateCubit>();
    final initialDate = refund
        ? (refundCubit.state ?? receivedCubit.state)
        : receivedCubit.state;
    final date = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (date != null && mounted) {
      if (refund)
        refundCubit.pick(date);
      else
        receivedCubit.pick(date);
    }
  }

  String? _idValidator(String? value) =>
      value == null || value.trim().isEmpty
          ? 'Stay ID is required.'
          : int.tryParse(value.trim()) == null
              ? 'Enter a valid stay ID.'
              : null;

  String? _amountValidator(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    final amount = double.tryParse(value.trim());
    return amount == null || amount <= 0 ? 'Enter a positive $label.' : null;
  }

  void _submit(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final now = DateTime.now();
    final receivedDate = context.read<_ReceivedDateCubit>().state;
    final refundDate = context.read<_RefundDateCubit>().state;
    final status = context.read<SelectedStatusCubit>().state;
    final deposit = DepositEntity(
      id: widget.deposit?.id,
      stayId: int.parse(_stayId.text.trim()),
      amount: double.parse(_amount.text.trim()),
      refundedAmount: double.parse(_refundedAmount.text.trim()),
      receivedDate: receivedDate,
      refundDate: refundDate,
      status: status,
      createdAt: widget.deposit?.createdAt ?? now,
      updatedAt: now,
    );
    context.read<SubmittingCubit>().start();
    if (_editing)
      context.read<DepositCubit>().updateDeposit(deposit);
    else
      context.read<DepositCubit>().createDeposit(deposit);
  }

  @override
  Widget build(BuildContext context) {
    final deposit = widget.deposit;
    return MultiBlocProvider(
      providers: [
        BlocProvider<SubmittingCubit>(create: (_) => SubmittingCubit()),
        BlocProvider<_ReceivedDateCubit>(
            create: (_) =>
                _ReceivedDateCubit(deposit?.receivedDate ?? DateTime.now())),
        BlocProvider<_RefundDateCubit>(
            create: (_) => _RefundDateCubit(deposit?.refundDate)),
        BlocProvider<SelectedStatusCubit>(
            create: (_) =>
                SelectedStatusCubit(deposit?.status ?? 'pending')),
      ],
      child: Builder(builder: (context) {
        return BlocListener<DepositCubit, DepositState>(
          listener: (context, state) {
            if (!context.read<SubmittingCubit>().state) return;
            if (state is DepositLoaded || state is DepositEmpty)
              context.pop(true);
            if (state is DepositError) {
              context.read<SubmittingCubit>().stop();
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          child: Scaffold(
            appBar: AppBar(
                title:
                    Text(_editing ? 'Edit Deposit' : 'Add Deposit')),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppTextField(
                              controller: _stayId,
                              label: 'Stay ID',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              validator: _idValidator),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                              controller: _amount,
                              label: 'Deposit Amount',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              validator: (v) =>
                                  _amountValidator(v, 'deposit amount')),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                              controller: _refundedAmount,
                              label: 'Refunded Amount',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              validator: (v) =>
                                  _amountValidator(v, 'refunded amount')),
                          const SizedBox(height: AppSpacing.md),
                          // Received Date (non-nullable)
                          BlocBuilder<_ReceivedDateCubit, DateTime?>(
                            builder: (context, receivedDate) => InkWell(
                              onTap: () => _pickDate(context, false),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                    labelText: 'Received Date',
                                    suffixIcon: Icon(
                                        Icons.calendar_today_outlined)),
                                child: Text(_date(receivedDate)),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          // Refund Date (nullable — clearable)
                          BlocBuilder<_RefundDateCubit, DateTime?>(
                            builder: (context, refundDate) => InkWell(
                              onTap: () => _pickDate(context, true),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                    labelText: 'Refund Date',
                                    suffixIcon: refundDate == null
                                        ? const Icon(
                                            Icons.calendar_today_outlined)
                                        : IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () => context
                                                .read<_RefundDateCubit>()
                                                .clear())),
                                child: Text(_date(refundDate)),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          BlocBuilder<SelectedStatusCubit, String>(
                            builder: (context, status) =>
                                DropdownButtonFormField<String>(
                              value: status,
                              decoration: const InputDecoration(
                                  labelText: 'Status'),
                              items: const [
                                'pending',
                                'held',
                                'refunded',
                                'forfeited'
                              ]
                                  .map((v) => DropdownMenuItem(
                                      value: v, child: Text(v)))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null)
                                  context
                                      .read<SelectedStatusCubit>()
                                      .select(value);
                              },
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          BlocBuilder<SubmittingCubit, bool>(
                            builder: (context, submitting) =>
                                BlocBuilder<DepositCubit, DepositState>(
                              builder: (context, state) => AppButton(
                                label: _editing
                                    ? 'Save Changes'
                                    : 'Add Deposit',
                                isLoading:
                                    submitting || state is DepositLoading,
                                isFullWidth: true,
                                onPressed: submitting
                                    ? null
                                    : () => _submit(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// Private typed wrappers to avoid type-key collision for two date cubits.
class _ReceivedDateCubit extends SelectedDateCubit {
  _ReceivedDateCubit(super.initial);

  @override
  DateTime get state => super.state ?? DateTime.now();
}

class _RefundDateCubit extends SelectedDateCubit {
  _RefundDateCubit(super.initial);
}
