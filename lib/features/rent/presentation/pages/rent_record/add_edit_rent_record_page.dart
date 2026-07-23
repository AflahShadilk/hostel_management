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
import '../../cubit/ui/balance_cubit.dart';
import '../../cubit/ui/selected_date_cubit.dart';
import '../../cubit/ui/selected_status_cubit.dart';
import '../../cubit/ui/submitting_cubit.dart';

/// Two cubits: one for startDate, one for endDate.
/// Using separate named keys to distinguish them via context.
class _StartDateCubit extends SelectedDateCubit {
  _StartDateCubit(super.initial);
}

class _EndDateCubit extends SelectedDateCubit {
  _EndDateCubit(super.initial);
}

class AddEditRentRecordPage extends StatefulWidget {
  final RentRecordEntity? record;
  const AddEditRentRecordPage({super.key, this.record});

  @override
  State<AddEditRentRecordPage> createState() => _AddEditRentRecordPageState();
}

class _AddEditRentRecordPageState extends State<AddEditRentRecordPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _stayId;
  late final TextEditingController _amountDue;
  late final TextEditingController _amountPaid;

  bool get _editing => widget.record != null;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _stayId = TextEditingController(text: record?.stayId.toString() ?? '');
    _amountDue =
        TextEditingController(text: record?.amountDue.toString() ?? '');
    _amountPaid =
        TextEditingController(text: record?.amountPaid.toString() ?? '0');
  }

  @override
  void dispose() {
    _stayId.dispose();
    _amountDue.dispose();
    _amountPaid.dispose();
    super.dispose();
  }

  String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  Future<void> _pickDate(
    BuildContext context,
    SelectedDateCubit cubit,
  ) async {
    final picked = await showDatePicker(
        context: context,
        initialDate: cubit.state ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (picked != null && mounted) cubit.pick(picked);
  }

  String? _amount(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    final amount = double.tryParse(value.trim());
    if (amount == null || amount < 0) return 'Enter a valid $label.';
    return null;
  }

  void _updateBalance(BuildContext context) {
    final due = double.tryParse(_amountDue.text) ?? 0;
    final paid = double.tryParse(_amountPaid.text) ?? 0;
    context.read<BalanceCubit>().update(due - paid);
  }

  void _submit(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final startDate = context.read<_StartDateCubit>().state ?? DateTime.now();
    final endDate = context.read<_EndDateCubit>().state ??
        DateTime(startDate.year, startDate.month + 1, startDate.day)
            .subtract(const Duration(days: 1));
    final status = context.read<SelectedStatusCubit>().state;
    final now = DateTime.now();

    final record = RentRecordEntity(
      id: widget.record?.id,
      stayId: int.parse(_stayId.text.trim()),
      startDate: startDate,
      endDate: endDate,
      dueDate: startDate,
      generatedAt: widget.record?.generatedAt ?? now,
      amountDue: double.parse(_amountDue.text.trim()),
      amountPaid: double.parse(_amountPaid.text.trim()),
      status: status,
      createdAt: widget.record?.createdAt ?? now,
      updatedAt: now,
    );
    context.read<SubmittingCubit>().start();
    if (_editing) {
      context.read<RentRecordCubit>().updateRentRecord(record);
    } else {
      context.read<RentRecordCubit>().createRentRecord(record);
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final initialBalance = (record?.amountDue ?? 0) - (record?.amountPaid ?? 0);
    final initialStart = record?.startDate ?? DateTime.now();
    final initialEnd = record?.endDate ??
        DateTime(initialStart.year, initialStart.month + 1, initialStart.day)
            .subtract(const Duration(days: 1));

    return MultiBlocProvider(
      providers: [
        BlocProvider<SubmittingCubit>(create: (_) => SubmittingCubit()),
        BlocProvider<_StartDateCubit>(
            create: (_) => _StartDateCubit(initialStart)),
        BlocProvider<_EndDateCubit>(create: (_) => _EndDateCubit(initialEnd)),
        BlocProvider<SelectedStatusCubit>(
            create: (_) =>
                SelectedStatusCubit(record?.status ?? RentStatus.pending)),
        BlocProvider<BalanceCubit>(create: (_) => BalanceCubit(initialBalance)),
      ],
      child: Builder(builder: (context) {
        return BlocListener<RentRecordCubit, RentRecordState>(
          listener: (context, state) {
            if (!context.read<SubmittingCubit>().state) return;
            if (state is RentRecordLoaded || state is RentRecordEmpty) {
              context.pop(true);
            } else if (state is RentRecordError) {
              context.read<SubmittingCubit>().stop();
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          child: Scaffold(
            appBar: AppBar(
                title: Text(_editing ? 'Edit Rent Record' : 'Add Rent Record')),
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
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Stay ID is required.';
                                }
                                return int.tryParse(v.trim()) == null
                                    ? 'Enter a valid Stay ID.'
                                    : null;
                              }),
                          const SizedBox(height: AppSpacing.md),
                          // Start Date picker
                          BlocBuilder<_StartDateCubit, DateTime?>(
                            builder: (context, startDate) => InkWell(
                              onTap: () => _pickDate(
                                  context, context.read<_StartDateCubit>()),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                    labelText: 'Billing Start Date',
                                    suffixIcon:
                                        Icon(Icons.calendar_today_outlined)),
                                child: Text(_date(startDate ?? DateTime.now())),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          // End Date picker
                          BlocBuilder<_EndDateCubit, DateTime?>(
                            builder: (context, endDate) => InkWell(
                              onTap: () => _pickDate(
                                  context, context.read<_EndDateCubit>()),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                    labelText: 'Billing End Date',
                                    suffixIcon:
                                        Icon(Icons.calendar_today_outlined)),
                                child: Text(_date(endDate ?? DateTime.now())),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _amountDue,
                            label: 'Rent Amount',
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            onChanged: (_) => _updateBalance(context),
                            validator: (v) => _amount(v, 'Rent amount'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _amountPaid,
                            label: 'Paid Amount',
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            onChanged: (_) => _updateBalance(context),
                            validator: (v) => _amount(v, 'Paid amount'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          BlocBuilder<BalanceCubit, double>(
                            builder: (context, balance) => InputDecorator(
                              decoration: const InputDecoration(
                                  labelText: 'Balance Amount'),
                              child: Text(balance.toStringAsFixed(2)),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          BlocBuilder<SelectedStatusCubit, String>(
                            builder: (context, status) =>
                                DropdownButtonFormField<String>(
                              value: status,
                              decoration:
                                  const InputDecoration(labelText: 'Status'),
                              items: RentStatus.values
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
                                BlocBuilder<RentRecordCubit, RentRecordState>(
                              builder: (context, state) => AppButton(
                                label: _editing
                                    ? 'Save Changes'
                                    : 'Add Rent Record',
                                isLoading:
                                    submitting || state is RentRecordLoading,
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
