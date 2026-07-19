import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../domain/constants/rent_status_constants.dart';
import '../../../domain/entities/rent_record_entity.dart';
import '../../cubit/rent_record/rent_record_cubit.dart';
import '../../cubit/rent_record/rent_record_state.dart';

class AddEditRentRecordPage extends StatefulWidget {
  final RentRecordEntity? record;
  const AddEditRentRecordPage({super.key, this.record});

  @override
  State<AddEditRentRecordPage> createState() => _AddEditRentRecordPageState();
}

class _AddEditRentRecordPageState extends State<AddEditRentRecordPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _stayId;
  late final TextEditingController _month;
  late final TextEditingController _year;
  late final TextEditingController _rentPeriod;
  late final TextEditingController _amountDue;
  late final TextEditingController _amountPaid;
  late DateTime _dueDate;
  late String _status;
  bool _submitting = false;

  bool get _editing => widget.record != null;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _stayId = TextEditingController(text: record?.stayId.toString() ?? '');
    _month = TextEditingController(text: record?.billingMonth.toString() ?? '');
    _year = TextEditingController(text: record?.billingYear.toString() ?? '');
    _rentPeriod = TextEditingController(text: record?.rentPeriod ?? '');
    _amountDue = TextEditingController(text: record?.amountDue.toString() ?? '');
    _amountPaid = TextEditingController(text: record?.amountPaid.toString() ?? '0');
    _dueDate = record?.dueDate ?? DateTime.now();
    _status = record?.status ?? RentStatus.pending;
  }

  @override
  void dispose() {
    _stayId.dispose(); _month.dispose(); _year.dispose(); _rentPeriod.dispose();
    _amountDue.dispose(); _amountPaid.dispose();
    super.dispose();
  }

  String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(context: context, initialDate: _dueDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (picked != null && mounted) setState(() => _dueDate = picked);
  }

  String? _integer(String? value, String label, {bool month = false}) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    final number = int.tryParse(value.trim());
    if (number == null) return 'Enter a valid $label.';
    if (month && (number < 1 || number > 12)) return 'Month must be between 1 and 12.';
    return null;
  }

  String? _amount(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    final amount = double.tryParse(value.trim());
    if (amount == null || amount <= 0) return 'Enter a valid $label.';
    return null;
  }

  double get _balance => (double.tryParse(_amountDue.text) ?? 0) - (double.tryParse(_amountPaid.text) ?? 0);

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final now = DateTime.now();
    final record = RentRecordEntity(
      id: widget.record?.id,
      stayId: int.parse(_stayId.text.trim()),
      billingMonth: int.parse(_month.text.trim()),
      billingYear: int.parse(_year.text.trim()),
      rentPeriod: _rentPeriod.text.trim(),
      dueDate: _dueDate,
      generatedAt: widget.record?.generatedAt ?? now,
      amountDue: double.parse(_amountDue.text.trim()),
      amountPaid: double.parse(_amountPaid.text.trim()),
      status: _status,
      createdAt: widget.record?.createdAt ?? now,
      updatedAt: now,
    );
    setState(() => _submitting = true);
    if (_editing) {
      context.read<RentRecordCubit>().updateRentRecord(record);
    } else {
      context.read<RentRecordCubit>().createRentRecord(record);
    }
  }

  @override
  Widget build(BuildContext context) => BlocListener<RentRecordCubit, RentRecordState>(
    listener: (context, state) {
      if (!_submitting) return;
      if (state is RentRecordLoaded || state is RentRecordEmpty) {
        context.pop(true);
      } else if (state is RentRecordError) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
      }
    },
    child: Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit Rent Record' : 'Add Rent Record')),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              AppTextField(controller: _stayId, label: 'Stay ID', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) => _integer(v, 'Stay ID')),
              const SizedBox(height: AppSpacing.md),
              AppTextField(controller: _month, label: 'Billing Month', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) => _integer(v, 'Billing month', month: true)),
              const SizedBox(height: AppSpacing.md),
              AppTextField(controller: _year, label: 'Billing Year', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) => _integer(v, 'Billing year')),
              const SizedBox(height: AppSpacing.md),
              AppTextField(controller: _rentPeriod, label: 'Rent Period', validator: (v) => v == null || v.trim().isEmpty ? 'Rent period is required.' : null),
              const SizedBox(height: AppSpacing.md),
              InkWell(onTap: _pickDueDate, child: InputDecorator(decoration: const InputDecoration(labelText: 'Due Date', suffixIcon: Icon(Icons.calendar_today_outlined)), child: Text(_date(_dueDate)))),
              const SizedBox(height: AppSpacing.md),
              AppTextField(controller: _amountDue, label: 'Rent Amount', keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => setState(() {}), validator: (v) => _amount(v, 'Rent amount')),
              const SizedBox(height: AppSpacing.md),
              AppTextField(controller: _amountPaid, label: 'Paid Amount', keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => setState(() {}), validator: (v) => _amount(v, 'Paid amount')),
              const SizedBox(height: AppSpacing.md),
              InputDecorator(decoration: const InputDecoration(labelText: 'Balance Amount'), child: Text(_balance.toStringAsFixed(2))),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(value: _status, decoration: const InputDecoration(labelText: 'Status'), items: RentStatus.values.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(), onChanged: (value) { if (value != null) setState(() => _status = value); }),
              const SizedBox(height: AppSpacing.xl),
              BlocBuilder<RentRecordCubit, RentRecordState>(builder: (context, state) => AppButton(label: _editing ? 'Save Changes' : 'Add Rent Record', isLoading: _submitting || state is RentRecordLoading, isFullWidth: true, onPressed: _submitting ? null : _submit)),
            ]),
          ),
        ),
      ))),
    ),
  );
}
