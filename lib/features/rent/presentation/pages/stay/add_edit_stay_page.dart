import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../domain/constants/rent_status_constants.dart';
import '../../../domain/entities/stay_entity.dart';
import '../../cubit/stay/stay_cubit.dart';
import '../../cubit/stay/stay_state.dart';

class AddEditStayPage extends StatefulWidget {
  final StayEntity? stay;

  const AddEditStayPage({super.key, this.stay});

  @override
  State<AddEditStayPage> createState() => _AddEditStayPageState();
}

class _AddEditStayPageState extends State<AddEditStayPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tenantId;
  late final TextEditingController _roomId;
  late final TextEditingController _bedId;
  late final TextEditingController _monthlyRent;
  late final TextEditingController _dailyRate;
  late DateTime _checkInDate;
  DateTime? _expectedCheckoutDate;
  late String _status;
  bool _submitting = false;

  bool get _isEditing => widget.stay != null;

  @override
  void initState() {
    super.initState();
    final stay = widget.stay;
    _tenantId = TextEditingController(text: stay?.tenantId.toString() ?? '');
    _roomId = TextEditingController(text: stay?.roomId.toString() ?? '');
    _bedId = TextEditingController(text: stay?.bedId.toString() ?? '');
    _monthlyRent = TextEditingController(
      text: stay?.monthlyRentSnapshot.toString() ?? '',
    );
    _dailyRate = TextEditingController(text: stay?.dailyRate.toString() ?? '');
    _checkInDate = stay?.checkInDate ?? DateTime.now();
    _expectedCheckoutDate = stay?.expectedCheckoutDate;
    _status = stay?.status ?? StayStatus.active;
  }

  @override
  void dispose() {
    _tenantId.dispose();
    _roomId.dispose();
    _bedId.dispose();
    _monthlyRent.dispose();
    _dailyRate.dispose();
    super.dispose();
  }

  String _date(DateTime? value) {
    if (value == null) return 'Select date';
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  Future<void> _pickDate({required bool expected}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: expected ? (_expectedCheckoutDate ?? _checkInDate) : _checkInDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (expected) {
        _expectedCheckoutDate = picked;
      } else {
        _checkInDate = picked;
      }
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final now = DateTime.now();
    final stay = StayEntity(
      id: widget.stay?.id,
      tenantId: int.parse(_tenantId.text.trim()),
      roomId: int.parse(_roomId.text.trim()),
      bedId: int.parse(_bedId.text.trim()),
      checkInDate: _checkInDate,
      checkOutDate: widget.stay?.checkOutDate,
      expectedCheckoutDate: _expectedCheckoutDate,
      monthlyRentSnapshot: double.parse(_monthlyRent.text.trim()),
      dailyRate: double.parse(_dailyRate.text.trim()),
      status: _status,
      createdAt: widget.stay?.createdAt ?? now,
      updatedAt: now,
    );
    setState(() => _submitting = true);
    final cubit = context.read<StayCubit>();
    if (_isEditing) {
      cubit.updateStay(stay);
    } else {
      cubit.createStay(stay);
    }
  }

  String? _requiredInteger(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    if (int.tryParse(value.trim()) == null) return 'Enter a valid $label.';
    return null;
  }

  String? _requiredNumber(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    if (double.tryParse(value.trim()) == null) return 'Enter a valid $label.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StayCubit, StayState>(
      listener: (context, state) {
        if (!_submitting) return;
        if (state is StayLoaded || state is StayEmpty) {
          context.pop(true);
        } else if (state is StayError) {
          setState(() => _submitting = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_isEditing ? 'Edit Stay' : 'Add Stay')),
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
                      AppTextField(controller: _tenantId, label: 'Tenant ID', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) => _requiredInteger(v, 'Tenant ID')),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(controller: _roomId, label: 'Room ID', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) => _requiredInteger(v, 'Room ID')),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(controller: _bedId, label: 'Bed ID', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) => _requiredInteger(v, 'Bed ID')),
                      const SizedBox(height: AppSpacing.md),
                      _DateInput(label: 'Check-in Date', value: _date(_checkInDate), onTap: () => _pickDate(expected: false)),
                      const SizedBox(height: AppSpacing.md),
                      _DateInput(label: 'Expected Checkout Date', value: _date(_expectedCheckoutDate), onTap: () => _pickDate(expected: true), onClear: _expectedCheckoutDate == null ? null : () => setState(() => _expectedCheckoutDate = null)),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(controller: _monthlyRent, label: 'Monthly Rent', keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) => _requiredNumber(v, 'Monthly rent')),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(controller: _dailyRate, label: 'Daily Rate', keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) => _requiredNumber(v, 'Daily rate')),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: StayStatus.values.map((status) => DropdownMenuItem(value: status, child: Text(status))).toList(),
                        onChanged: (value) { if (value != null) setState(() => _status = value); },
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      BlocBuilder<StayCubit, StayState>(
                        builder: (context, state) => AppButton(
                          label: _isEditing ? 'Save Changes' : 'Add Stay',
                          isLoading: _submitting || state is StayLoading,
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

class _DateInput extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  const _DateInput({required this.label, required this.value, required this.onTap, this.onClear});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: InputDecorator(
      decoration: InputDecoration(labelText: label, suffixIcon: onClear == null ? const Icon(Icons.calendar_today_outlined) : IconButton(icon: const Icon(Icons.clear), onPressed: onClear)),
      child: Text(value),
    ),
  );
}
