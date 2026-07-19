import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../domain/constants/rent_status_constants.dart';
import '../../../domain/entities/checkout_settlement_entity.dart';
import '../../cubit/checkout/checkout_cubit.dart';
import '../../cubit/checkout/checkout_state.dart';

class AddEditCheckoutPage extends StatefulWidget {
  final CheckoutSettlementEntity? settlement;

  const AddEditCheckoutPage({super.key, this.settlement});

  @override
  State<AddEditCheckoutPage> createState() => _AddEditCheckoutPageState();
}

class _AddEditCheckoutPageState extends State<AddEditCheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _stayId;
  late final TextEditingController _charges;
  late final TextEditingController _refund;
  late DateTime _checkoutDate;
  late String _status;
  bool _submitting = false;

  bool get _editing => widget.settlement != null;

  @override
  void initState() {
    super.initState();
    final settlement = widget.settlement;
    _stayId = TextEditingController(text: settlement?.stayId.toString() ?? '');
    _charges = TextEditingController(
      text: settlement?.finalAmount.toString() ?? '',
    );
    _refund = TextEditingController(
      text: settlement?.refundAmount.toString() ?? '',
    );
    _checkoutDate = settlement?.settlementDate ?? DateTime.now();
    _status = settlement?.status ?? SettlementStatus.draft;
  }

  @override
  void dispose() {
    _stayId.dispose();
    _charges.dispose();
    _refund.dispose();
    super.dispose();
  }

  String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _checkoutDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (value != null && mounted) setState(() => _checkoutDate = value);
  }

  String? _idValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Stay ID is required.';
    return int.tryParse(value.trim()) == null ? 'Enter a valid stay ID.' : null;
  }

  String? _amountValidator(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    final amount = double.tryParse(value.trim());
    return amount == null || amount <= 0 ? 'Enter a positive $label.' : null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final existing = widget.settlement;
    final now = DateTime.now();
    final settlement = CheckoutSettlementEntity(
      id: existing?.id,
      stayId: int.parse(_stayId.text.trim()),
      outstandingAmount: existing?.outstandingAmount ?? 0,
      rentDue: existing?.rentDue ?? 0,
      lateFee: existing?.lateFee ?? 0,
      damageCharges: existing?.damageCharges ?? 0,
      depositAdjustment: existing?.depositAdjustment ?? 0,
      refundAmount: double.parse(_refund.text.trim()),
      finalAmount: double.parse(_charges.text.trim()),
      settlementDate: _checkoutDate,
      status: _status,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    setState(() => _submitting = true);
    if (_editing) {
      context.read<CheckoutCubit>().updateCheckoutSettlement(settlement);
    } else {
      context.read<CheckoutCubit>().createCheckoutSettlement(settlement);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CheckoutCubit, CheckoutState>(
      listener: (context, state) {
        if (!_submitting) return;
        if (state is CheckoutLoaded || state is CheckoutEmpty) {
          context.pop(true);
        } else if (state is CheckoutError) {
          setState(() => _submitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_editing ? 'Edit Checkout' : 'Add Checkout'),
        ),
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
                        validator: _idValidator,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      InkWell(
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Checkout Date',
                            suffixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          child: Text(_date(_checkoutDate)),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _charges,
                        label: 'Total Charges',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) =>
                            _amountValidator(value, 'total charges'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _refund,
                        label: 'Total Refund',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) =>
                            _amountValidator(value, 'total refund'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: SettlementStatus.values
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _status = value);
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      BlocBuilder<CheckoutCubit, CheckoutState>(
                        builder: (context, state) => AppButton(
                          label: _editing ? 'Save Changes' : 'Add Checkout',
                          isLoading: _submitting || state is CheckoutLoading,
                          isFullWidth: true,
                          onPressed: _submitting ? null : _submit,
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
  }
}
