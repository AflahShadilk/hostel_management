import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../domain/entities/receipt_entity.dart';
import '../../cubit/receipt/receipt_cubit.dart';
import '../../cubit/receipt/receipt_state.dart';

class AddEditReceiptPage extends StatefulWidget {
  final ReceiptEntity? receipt;
  const AddEditReceiptPage({super.key, this.receipt});
  @override
  State<AddEditReceiptPage> createState() => _AddEditReceiptPageState();
}

class _AddEditReceiptPageState extends State<AddEditReceiptPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _paymentId;
  late final TextEditingController _receiptNumber;
  late final TextEditingController _amount;
  late final TextEditingController _method;
  late DateTime _issuedAt;
  bool _submitting = false;
  bool get _editing => widget.receipt != null;

  @override
  void initState() {
    super.initState();
    final receipt = widget.receipt;
    _paymentId = TextEditingController(text: receipt?.paymentId.toString() ?? '');
    _receiptNumber = TextEditingController(text: receipt?.receiptNumber ?? '');
    _amount = TextEditingController(text: receipt?.paymentAmountSnapshot.toString() ?? '');
    _method = TextEditingController(text: receipt?.paymentMethodSnapshot ?? '');
    _issuedAt = receipt?.issuedAt ?? DateTime.now();
  }

  @override
  void dispose() { _paymentId.dispose(); _receiptNumber.dispose(); _amount.dispose(); _method.dispose(); super.dispose(); }
  String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}/' '${value.month.toString().padLeft(2, '0')}/${value.year}';
  Future<void> _pickDate() async {
    final value = await showDatePicker(context: context, initialDate: _issuedAt, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (value != null && mounted) setState(() => _issuedAt = value);
  }
  String? _paymentIdValidator(String? value) => value == null || value.trim().isEmpty ? 'Payment ID is required.' : int.tryParse(value.trim()) == null ? 'Enter a valid payment ID.' : null;
  String? _amountValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Payment amount is required.';
    final amount = double.tryParse(value.trim());
    return amount == null || amount <= 0 ? 'Enter a positive amount.' : null;
  }
  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final now = DateTime.now();
    final receipt = ReceiptEntity(id: widget.receipt?.id, paymentId: int.parse(_paymentId.text.trim()), receiptNumber: _receiptNumber.text.trim(), paymentAmountSnapshot: double.parse(_amount.text.trim()), paymentMethodSnapshot: _method.text.trim(), issuedAt: _issuedAt, createdAt: widget.receipt?.createdAt ?? now, updatedAt: now);
    setState(() => _submitting = true);
    if (_editing) context.read<ReceiptCubit>().updateReceipt(receipt); else context.read<ReceiptCubit>().createReceipt(receipt);
  }

  @override
  Widget build(BuildContext context) => BlocListener<ReceiptCubit, ReceiptState>(
    listener: (context, state) {
      if (!_submitting) return;
      if (state is ReceiptLoaded || state is ReceiptEmpty) context.pop(true);
      if (state is ReceiptError) { setState(() => _submitting = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message))); }
    },
    child: Scaffold(appBar: AppBar(title: Text(_editing ? 'Edit Receipt' : 'Add Receipt')), body: SafeArea(child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: SingleChildScrollView(padding: const EdgeInsets.all(AppSpacing.md), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AppTextField(controller: _paymentId, label: 'Payment ID', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: _paymentIdValidator),
        const SizedBox(height: AppSpacing.md),
        AppTextField(controller: _receiptNumber, label: 'Receipt Number', validator: (value) => value == null || value.trim().isEmpty ? 'Receipt number is required.' : null),
        const SizedBox(height: AppSpacing.md),
        AppTextField(controller: _amount, label: 'Payment Amount', keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _amountValidator),
        const SizedBox(height: AppSpacing.md),
        AppTextField(controller: _method, label: 'Payment Method', validator: (value) => value == null || value.trim().isEmpty ? 'Payment method is required.' : null),
        const SizedBox(height: AppSpacing.md),
        InkWell(onTap: _pickDate, child: InputDecorator(decoration: const InputDecoration(labelText: 'Issued Date', suffixIcon: Icon(Icons.calendar_today_outlined)), child: Text(_date(_issuedAt)))),
        const SizedBox(height: AppSpacing.xl),
        BlocBuilder<ReceiptCubit, ReceiptState>(builder: (context, state) => AppButton(label: _editing ? 'Save Changes' : 'Add Receipt', isLoading: _submitting || state is ReceiptLoading, isFullWidth: true, onPressed: _submitting ? null : _submit)),
      ]))),
    )))),
  );
}
