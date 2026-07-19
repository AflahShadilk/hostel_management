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

class AddEditDepositPage extends StatefulWidget { final DepositEntity? deposit; const AddEditDepositPage({super.key, this.deposit}); @override State<AddEditDepositPage> createState() => _AddEditDepositPageState(); }
class _AddEditDepositPageState extends State<AddEditDepositPage> {
  final _formKey = GlobalKey<FormState>(); late final TextEditingController _stayId; late final TextEditingController _amount; late final TextEditingController _refundedAmount; late DateTime _receivedDate; DateTime? _refundDate; late String _status; bool _submitting = false;
  bool get _editing => widget.deposit != null;
  @override void initState() { super.initState(); final deposit = widget.deposit; _stayId = TextEditingController(text: deposit?.stayId.toString() ?? ''); _amount = TextEditingController(text: deposit?.amount.toString() ?? ''); _refundedAmount = TextEditingController(text: deposit?.refundedAmount.toString() ?? ''); _receivedDate = deposit?.receivedDate ?? DateTime.now(); _refundDate = deposit?.refundDate; _status = deposit?.status ?? 'pending'; }
  @override void dispose() { _stayId.dispose(); _amount.dispose(); _refundedAmount.dispose(); super.dispose(); }
  String _date(DateTime? value) => value == null ? 'Select date' : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  Future<void> _pickDate(bool refund) async { final date = await showDatePicker(context: context, initialDate: refund ? (_refundDate ?? _receivedDate) : _receivedDate, firstDate: DateTime(2000), lastDate: DateTime(2100)); if (date != null && mounted) setState(() { if (refund) _refundDate = date; else _receivedDate = date; }); }
  String? _idValidator(String? value) => value == null || value.trim().isEmpty ? 'Stay ID is required.' : int.tryParse(value.trim()) == null ? 'Enter a valid stay ID.' : null;
  String? _amountValidator(String? value, String label) { if (value == null || value.trim().isEmpty) return '$label is required.'; final amount = double.tryParse(value.trim()); return amount == null || amount <= 0 ? 'Enter a positive $label.' : null; }
  void _submit() { if (!(_formKey.currentState?.validate() ?? false)) return; final now = DateTime.now(); final deposit = DepositEntity(id: widget.deposit?.id, stayId: int.parse(_stayId.text.trim()), amount: double.parse(_amount.text.trim()), refundedAmount: double.parse(_refundedAmount.text.trim()), receivedDate: _receivedDate, refundDate: _refundDate, status: _status, createdAt: widget.deposit?.createdAt ?? now, updatedAt: now); setState(() => _submitting = true); if (_editing) context.read<DepositCubit>().updateDeposit(deposit); else context.read<DepositCubit>().createDeposit(deposit); }
  @override Widget build(BuildContext context) => BlocListener<DepositCubit, DepositState>(listener: (context, state) { if (!_submitting) return; if (state is DepositLoaded || state is DepositEmpty) context.pop(true); if (state is DepositError) { setState(() => _submitting = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message))); } }, child: Scaffold(appBar: AppBar(title: Text(_editing ? 'Edit Deposit' : 'Add Deposit')), body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: SingleChildScrollView(padding: const EdgeInsets.all(AppSpacing.md), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    AppTextField(controller: _stayId, label: 'Stay ID', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: _idValidator), const SizedBox(height: AppSpacing.md),
    AppTextField(controller: _amount, label: 'Deposit Amount', keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) => _amountValidator(v, 'deposit amount')), const SizedBox(height: AppSpacing.md),
    AppTextField(controller: _refundedAmount, label: 'Refunded Amount', keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) => _amountValidator(v, 'refunded amount')), const SizedBox(height: AppSpacing.md),
    InkWell(onTap: () => _pickDate(false), child: InputDecorator(decoration: const InputDecoration(labelText: 'Received Date', suffixIcon: Icon(Icons.calendar_today_outlined)), child: Text(_date(_receivedDate)))), const SizedBox(height: AppSpacing.md),
    InkWell(onTap: () => _pickDate(true), child: InputDecorator(decoration: InputDecoration(labelText: 'Refund Date', suffixIcon: _refundDate == null ? const Icon(Icons.calendar_today_outlined) : IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _refundDate = null))), child: Text(_date(_refundDate)))), const SizedBox(height: AppSpacing.md),
    DropdownButtonFormField<String>(value: _status, decoration: const InputDecoration(labelText: 'Status'), items: const ['pending', 'held', 'refunded', 'forfeited'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(), onChanged: (value) { if (value != null) setState(() => _status = value); }), const SizedBox(height: AppSpacing.xl),
    BlocBuilder<DepositCubit, DepositState>(builder: (context, state) => AppButton(label: _editing ? 'Save Changes' : 'Add Deposit', isLoading: _submitting || state is DepositLoading, isFullWidth: true, onPressed: _submitting ? null : _submit)),
  ]))))))));
}
