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
import '../../cubit/ui/selected_date_cubit.dart';
import '../../cubit/ui/selected_status_cubit.dart';
import '../../cubit/ui/submitting_cubit.dart';

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

  Future<void> _pickDate(BuildContext context,
      {required bool expected}) async {
    final checkInCubit = context.read<_CheckInDateCubit>();
    final expectedCubit = context.read<_ExpectedCheckoutDateCubit>();
    final initialDate = expected
        ? (expectedCubit.state ?? checkInCubit.state)
        : checkInCubit.state;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    if (expected) {
      expectedCubit.pick(picked);
    } else {
      checkInCubit.pick(picked);
    }
  }

  void _submit(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final now = DateTime.now();
    final checkInDate = context.read<_CheckInDateCubit>().state;
    final expectedCheckoutDate =
        context.read<_ExpectedCheckoutDateCubit>().state;
    final status = context.read<SelectedStatusCubit>().state;
    final stay = StayEntity(
      id: widget.stay?.id,
      tenantId: int.parse(_tenantId.text.trim()),
      roomId: int.parse(_roomId.text.trim()),
      bedId: int.parse(_bedId.text.trim()),
      checkInDate: checkInDate,
      checkOutDate: widget.stay?.checkOutDate,
      expectedCheckoutDate: expectedCheckoutDate,
      monthlyRentSnapshot: double.parse(_monthlyRent.text.trim()),
      dailyRate: double.parse(_dailyRate.text.trim()),
      status: status,
      createdAt: widget.stay?.createdAt ?? now,
      updatedAt: now,
    );
    context.read<SubmittingCubit>().start();
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
    final stay = widget.stay;
    return MultiBlocProvider(
      providers: [
        BlocProvider<SubmittingCubit>(create: (_) => SubmittingCubit()),
        BlocProvider<_CheckInDateCubit>(
            create: (_) => _CheckInDateCubit(stay?.checkInDate ?? DateTime.now())),
        BlocProvider<_ExpectedCheckoutDateCubit>(
            create: (_) => _ExpectedCheckoutDateCubit(stay?.expectedCheckoutDate)),
        BlocProvider<SelectedStatusCubit>(
            create: (_) => SelectedStatusCubit(stay?.status ?? StayStatus.active)),
      ],
      child: Builder(builder: (context) {
        return BlocListener<StayCubit, StayState>(
          listener: (context, state) {
            if (!context.read<SubmittingCubit>().state) return;
            if (state is StayLoaded || state is StayEmpty) {
              context.pop(true);
            } else if (state is StayError) {
              context.read<SubmittingCubit>().stop();
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          child: Scaffold(
            appBar:
                AppBar(title: Text(_isEditing ? 'Edit Stay' : 'Add Stay')),
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
                              controller: _tenantId,
                              label: 'Tenant ID',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              validator: (v) =>
                                  _requiredInteger(v, 'Tenant ID')),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                              controller: _roomId,
                              label: 'Room ID',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              validator: (v) =>
                                  _requiredInteger(v, 'Room ID')),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                              controller: _bedId,
                              label: 'Bed ID',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              validator: (v) =>
                                  _requiredInteger(v, 'Bed ID')),
                          const SizedBox(height: AppSpacing.md),
                          // Check-in Date
                          BlocBuilder<_CheckInDateCubit, DateTime?>(
                            builder: (context, checkInDate) => _DateInput(
                              label: 'Check-in Date',
                              value: _date(checkInDate),
                              onTap: () =>
                                  _pickDate(context, expected: false),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          // Expected Checkout Date
                          BlocBuilder<_ExpectedCheckoutDateCubit, DateTime?>(
                            builder: (context, expectedDate) => _DateInput(
                              label: 'Expected Checkout Date',
                              value: _date(expectedDate),
                              onTap: () =>
                                  _pickDate(context, expected: true),
                              onClear: expectedDate == null
                                  ? null
                                  : () => context
                                      .read<_ExpectedCheckoutDateCubit>()
                                      .clear(),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                              controller: _monthlyRent,
                              label: 'Monthly Rent',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              validator: (v) =>
                                  _requiredNumber(v, 'Monthly rent')),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                              controller: _dailyRate,
                              label: 'Daily Rate',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              validator: (v) =>
                                  _requiredNumber(v, 'Daily rate')),
                          const SizedBox(height: AppSpacing.md),
                          BlocBuilder<SelectedStatusCubit, String>(
                            builder: (context, status) =>
                                DropdownButtonFormField<String>(
                              value: status,
                              decoration: const InputDecoration(
                                  labelText: 'Status'),
                              items: StayStatus.values
                                  .map((s) => DropdownMenuItem(
                                      value: s, child: Text(s)))
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
                                BlocBuilder<StayCubit, StayState>(
                              builder: (context, state) => AppButton(
                                label: _isEditing
                                    ? 'Save Changes'
                                    : 'Add Stay',
                                isLoading:
                                    submitting || state is StayLoading,
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

// Private typed wrappers so two SelectedDateCubit instances can coexist
// in the same widget tree without type-key collisions.
class _CheckInDateCubit extends SelectedDateCubit {
  _CheckInDateCubit(super.initial);

  @override
  DateTime get state => super.state ?? DateTime.now();
}

class _ExpectedCheckoutDateCubit extends SelectedDateCubit {
  _ExpectedCheckoutDateCubit(super.initial);
}

class _DateInput extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  const _DateInput(
      {required this.label,
      required this.value,
      required this.onTap,
      this.onClear});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
              labelText: label,
              suffixIcon: onClear == null
                  ? const Icon(Icons.calendar_today_outlined)
                  : IconButton(
                      icon: const Icon(Icons.clear), onPressed: onClear)),
          child: Text(value),
        ),
      );
}
