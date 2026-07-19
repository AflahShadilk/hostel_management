import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../domain/constants/rent_status_constants.dart';
import '../../../domain/entities/payment_entity.dart';
import '../../cubit/payment/payment_cubit.dart';
import '../../cubit/payment/payment_state.dart';
import '../../cubit/ui/selected_date_cubit.dart';
import '../../cubit/ui/selected_status_cubit.dart';
import '../../cubit/ui/submitting_cubit.dart';

class AddEditPaymentPage extends StatefulWidget {
  final PaymentEntity? payment;
  const AddEditPaymentPage({super.key, this.payment});

  @override
  State<AddEditPaymentPage> createState() => _AddEditPaymentPageState();
}

class _AddEditPaymentPageState extends State<AddEditPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _rentRecordId;
  late final TextEditingController _amount;
  late final TextEditingController _paymentMethod;
  bool get _editing => widget.payment != null;

  @override
  void initState() {
    super.initState();
    final payment = widget.payment;
    _rentRecordId =
        TextEditingController(text: payment?.rentRecordId.toString() ?? '');
    _amount = TextEditingController(text: payment?.amount.toString() ?? '');
    _paymentMethod =
        TextEditingController(text: payment?.paymentMethod ?? '');
  }

  @override
  void dispose() {
    _rentRecordId.dispose();
    _amount.dispose();
    _paymentMethod.dispose();
    super.dispose();
  }

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  Future<void> _pickDate(BuildContext context) async {
    final cubit = context.read<SelectedDateCubit>();
    final value = await showDatePicker(
        context: context,
        initialDate: cubit.state ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (value != null && mounted) cubit.pick(value);
  }

  String? _idValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Rent record ID is required.';
    }
    return int.tryParse(value.trim()) == null
        ? 'Enter a valid rent record ID.'
        : null;
  }

  String? _amountValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Amount is required.';
    final amount = double.tryParse(value.trim());
    return amount == null || amount <= 0 ? 'Enter a positive amount.' : null;
  }

  void _submit(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final now = DateTime.now();
    final paymentDate =
        context.read<SelectedDateCubit>().state ?? DateTime.now();
    final status = context.read<SelectedStatusCubit>().state;
    final payment = PaymentEntity(
      id: widget.payment?.id,
      rentRecordId: int.parse(_rentRecordId.text.trim()),
      amount: double.parse(_amount.text.trim()),
      paymentDate: paymentDate,
      paymentMethod: _paymentMethod.text.trim(),
      status: status,
      createdAt: widget.payment?.createdAt ?? now,
      updatedAt: now,
    );
    context.read<SubmittingCubit>().start();
    if (_editing) {
      context.read<PaymentCubit>().updatePayment(payment);
    } else {
      context.read<PaymentCubit>().createPayment(payment);
    }
  }

  @override
  Widget build(BuildContext context) {
    final payment = widget.payment;
    return MultiBlocProvider(
      providers: [
        BlocProvider<SubmittingCubit>(create: (_) => SubmittingCubit()),
        BlocProvider<SelectedDateCubit>(
            create: (_) =>
                SelectedDateCubit(payment?.paymentDate ?? DateTime.now())),
        BlocProvider<SelectedStatusCubit>(
            create: (_) =>
                SelectedStatusCubit(payment?.status ?? PaymentStatus.completed)),
      ],
      child: Builder(builder: (context) {
        return BlocListener<PaymentCubit, PaymentState>(
          listener: (context, state) {
            if (!context.read<SubmittingCubit>().state) return;
            if (state is PaymentLoaded || state is PaymentEmpty) {
              context.pop(true);
            }
            if (state is PaymentError) {
              context.read<SubmittingCubit>().stop();
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          child: Scaffold(
            appBar: AppBar(
                title:
                    Text(_editing ? 'Edit Payment' : 'Add Payment')),
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
                              controller: _rentRecordId,
                              label: 'Rent Record ID',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              validator: _idValidator),
                          const SizedBox(height: AppSpacing.md),
                          BlocBuilder<SelectedDateCubit, DateTime?>(
                            builder: (context, paymentDate) => InkWell(
                              onTap: () => _pickDate(context),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                    labelText: 'Payment Date',
                                    suffixIcon: Icon(
                                        Icons.calendar_today_outlined)),
                                child: Text(
                                    _date(paymentDate ?? DateTime.now())),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                              controller: _amount,
                              label: 'Amount',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              validator: _amountValidator),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                              controller: _paymentMethod,
                              label: 'Payment Method',
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                      ? 'Payment method is required.'
                                      : null),
                          const SizedBox(height: AppSpacing.md),
                          BlocBuilder<SelectedStatusCubit, String>(
                            builder: (context, status) =>
                                DropdownButtonFormField<String>(
                              value: status,
                              decoration: const InputDecoration(
                                  labelText: 'Status'),
                              items: PaymentStatus.values
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
                                BlocBuilder<PaymentCubit, PaymentState>(
                              builder: (context, state) => AppButton(
                                label: _editing
                                    ? 'Save Changes'
                                    : 'Add Payment',
                                isLoading:
                                    submitting || state is PaymentLoading,
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
