import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../domain/entities/checkout_settlement_entity.dart';
import '../../cubit/checkout/checkout_cubit.dart';
import '../../cubit/checkout/checkout_state.dart';
import '../../cubit/ui/selected_date_cubit.dart';
import '../../cubit/ui/selected_status_cubit.dart';
import '../../cubit/ui/submitting_cubit.dart';

class AddEditCheckoutPage extends StatefulWidget {
  final CheckoutSettlementEntity? settlement;
  const AddEditCheckoutPage({super.key, this.settlement});

  @override
  State<AddEditCheckoutPage> createState() => _AddEditCheckoutPageState();
}

class _AddEditCheckoutPageState extends State<AddEditCheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _stayId;
  late final TextEditingController _outstandingAmount;
  late final TextEditingController _rentDue;
  late final TextEditingController _lateFee;
  late final TextEditingController _damageCharges;
  late final TextEditingController _depositAdjustment;
  late final TextEditingController _refundAmount;
  late final TextEditingController _finalAmount;

  bool get _editing => widget.settlement != null;

  @override
  void initState() {
    super.initState();
    final c = widget.settlement;
    _stayId = TextEditingController(text: c?.stayId.toString() ?? '');
    _outstandingAmount =
        TextEditingController(text: c?.outstandingAmount.toString() ?? '');
    _rentDue = TextEditingController(text: c?.rentDue.toString() ?? '');
    _lateFee = TextEditingController(text: c?.lateFee.toString() ?? '');
    _damageCharges =
        TextEditingController(text: c?.damageCharges.toString() ?? '');
    _depositAdjustment =
        TextEditingController(text: c?.depositAdjustment.toString() ?? '');
    _refundAmount =
        TextEditingController(text: c?.refundAmount.toString() ?? '');
    _finalAmount = TextEditingController(text: c?.finalAmount.toString() ?? '');
  }

  @override
  void dispose() {
    _stayId.dispose();
    _outstandingAmount.dispose();
    _rentDue.dispose();
    _lateFee.dispose();
    _damageCharges.dispose();
    _depositAdjustment.dispose();
    _refundAmount.dispose();
    _finalAmount.dispose();
    super.dispose();
  }

  String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  Future<void> _pickDate(BuildContext context) async {
    final cubit = context.read<SelectedDateCubit>();
    final date = await showDatePicker(
        context: context,
        initialDate: cubit.state ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (date != null && context.mounted) cubit.pick(date);
  }

  String? _idValidator(String? value) => value == null || value.trim().isEmpty
      ? 'Stay ID is required.'
      : int.tryParse(value.trim()) == null
          ? 'Enter a valid stay ID.'
          : null;

  String? _amountValidator(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    final amount = double.tryParse(value.trim());
    return amount == null ? 'Enter a valid numeric $label.' : null;
  }

  void _submit(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final now = DateTime.now();
    final checkoutDate =
        context.read<SelectedDateCubit>().state ?? DateTime.now();
    final status = context.read<SelectedStatusCubit>().state;
    final entity = CheckoutSettlementEntity(
      id: widget.settlement?.id,
      stayId: int.parse(_stayId.text.trim()),
      settlementDate: checkoutDate,
      outstandingAmount: double.parse(_outstandingAmount.text.trim()),
      currentMonthCharge: widget.settlement?.currentMonthCharge ?? 0,
      rentDue: double.parse(_rentDue.text.trim()),
      lateFee: double.parse(_lateFee.text.trim()),
      damageCharges: double.parse(_damageCharges.text.trim()),
      depositAdjustment: double.parse(_depositAdjustment.text.trim()),
      refundAmount: double.parse(_refundAmount.text.trim()),
      finalAmount: double.parse(_finalAmount.text.trim()),
      status: status,
      createdAt: widget.settlement?.createdAt ?? now,
      updatedAt: now,
    );
    context.read<SubmittingCubit>().start();
    if (_editing) {
      context.read<CheckoutCubit>().updateCheckoutSettlement(entity);
    } else {
      context.read<CheckoutCubit>().createCheckoutSettlement(entity);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.settlement;
    return MultiBlocProvider(
      providers: [
        BlocProvider<SubmittingCubit>(create: (_) => SubmittingCubit()),
        BlocProvider<SelectedDateCubit>(
            create: (_) =>
                SelectedDateCubit(c?.settlementDate ?? DateTime.now())),
        BlocProvider<SelectedStatusCubit>(
            create: (_) => SelectedStatusCubit(c?.status ?? 'pending')),
      ],
      child: Builder(builder: (context) {
        return BlocListener<CheckoutCubit, CheckoutState>(
          listener: (context, state) {
            if (!context.read<SubmittingCubit>().state) return;
            if (state is CheckoutLoaded || state is CheckoutEmpty) {
              context.pop(true);
            }
            if (state is CheckoutError) {
              context.read<SubmittingCubit>().stop();
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          child: Scaffold(
            appBar: AppBar(
                title: Text(_editing ? 'Edit Checkout' : 'Add Checkout')),
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
                          BlocBuilder<SelectedDateCubit, DateTime?>(
                            builder: (context, date) => InkWell(
                              onTap: () => _pickDate(context),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                    labelText: 'Settlement Date',
                                    suffixIcon:
                                        Icon(Icons.calendar_today_outlined)),
                                child: Text(_date(date ?? DateTime.now())),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                              controller: _outstandingAmount,
                              label: 'Outstanding Amount',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              validator: (v) =>
                                  _amountValidator(v, 'outstanding amount')),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                              controller: _rentDue,
                              label: 'Rent Due',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              validator: (v) =>
                                  _amountValidator(v, 'rent due')),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                              controller: _lateFee,
                              label: 'Late Fee',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              validator: (v) =>
                                  _amountValidator(v, 'late fee')),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                              controller: _damageCharges,
                              label: 'Damage Charges',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              validator: (v) =>
                                  _amountValidator(v, 'damage charges')),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                              controller: _depositAdjustment,
                              label: 'Deposit Adjustment',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              validator: (v) =>
                                  _amountValidator(v, 'deposit adjustment')),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                              controller: _refundAmount,
                              label: 'Refund Amount',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              validator: (v) =>
                                  _amountValidator(v, 'refund amount')),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                              controller: _finalAmount,
                              label: 'Final Amount',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              validator: (v) =>
                                  _amountValidator(v, 'final amount')),
                          const SizedBox(height: AppSpacing.md),
                          BlocBuilder<SelectedStatusCubit, String>(
                            builder: (context, status) =>
                                DropdownButtonFormField<String>(
                              value: status,
                              decoration:
                                  const InputDecoration(labelText: 'Status'),
                              items: const ['pending', 'completed']
                                  .map((v) => DropdownMenuItem(
                                      value: v, child: Text(v)))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  context
                                      .read<SelectedStatusCubit>()
                                      .select(value);
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          BlocBuilder<SubmittingCubit, bool>(
                            builder: (context, submitting) =>
                                BlocBuilder<CheckoutCubit, CheckoutState>(
                              builder: (context, state) => AppButton(
                                label:
                                    _editing ? 'Save Changes' : 'Add Checkout',
                                isLoading:
                                    submitting || state is CheckoutLoading,
                                isFullWidth: true,
                                onPressed:
                                    submitting ? null : () => _submit(context),
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
