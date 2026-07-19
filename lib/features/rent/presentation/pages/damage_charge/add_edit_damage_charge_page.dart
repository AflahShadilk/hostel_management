import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../domain/entities/damage_charge_entity.dart';
import '../../cubit/damage_charge/damage_charge_cubit.dart';
import '../../cubit/damage_charge/damage_charge_state.dart';
import '../../cubit/ui/selected_status_cubit.dart';
import '../../cubit/ui/submitting_cubit.dart';

class AddEditDamageChargePage extends StatefulWidget {
  final DamageChargeEntity? damageCharge;
  const AddEditDamageChargePage({super.key, this.damageCharge});
  @override
  State<AddEditDamageChargePage> createState() =>
      _AddEditDamageChargePageState();
}

class _AddEditDamageChargePageState extends State<AddEditDamageChargePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _stayId;
  late final TextEditingController _description;
  late final TextEditingController _amount;
  bool get _editing => widget.damageCharge != null;

  @override
  void initState() {
    super.initState();
    final charge = widget.damageCharge;
    _stayId =
        TextEditingController(text: charge?.stayId.toString() ?? '');
    _description =
        TextEditingController(text: charge?.description ?? '');
    _amount =
        TextEditingController(text: charge?.amount.toString() ?? '');
  }

  @override
  void dispose() {
    _stayId.dispose();
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  String? _idValidator(String? value) =>
      value == null || value.trim().isEmpty
          ? 'Stay ID is required.'
          : int.tryParse(value.trim()) == null
              ? 'Enter a valid stay ID.'
              : null;

  String? _amountValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Amount is required.';
    final amount = double.tryParse(value.trim());
    return amount == null || amount <= 0 ? 'Enter a positive amount.' : null;
  }

  void _submit(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final now = DateTime.now();
    final status = context.read<SelectedStatusCubit>().state;
    final charge = DamageChargeEntity(
      id: widget.damageCharge?.id,
      stayId: int.parse(_stayId.text.trim()),
      description: _description.text.trim(),
      amount: double.parse(_amount.text.trim()),
      status: status,
      createdAt: widget.damageCharge?.createdAt ?? now,
      updatedAt: now,
    );
    context.read<SubmittingCubit>().start();
    if (_editing) {
      context.read<DamageChargeCubit>().updateDamageCharge(charge);
    } else {
      context.read<DamageChargeCubit>().createDamageCharge(charge);
    }
  }

  @override
  Widget build(BuildContext context) {
    final charge = widget.damageCharge;
    return MultiBlocProvider(
      providers: [
        BlocProvider<SubmittingCubit>(create: (_) => SubmittingCubit()),
        BlocProvider<SelectedStatusCubit>(
            create: (_) =>
                SelectedStatusCubit(charge?.status ?? 'pending')),
      ],
      child: Builder(builder: (context) {
        return BlocListener<DamageChargeCubit, DamageChargeState>(
          listener: (context, state) {
            if (!context.read<SubmittingCubit>().state) return;
            if (state is DamageChargeLoaded || state is DamageChargeEmpty) {
              context.pop(true);
            }
            if (state is DamageChargeError) {
              context.read<SubmittingCubit>().stop();
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          child: Scaffold(
            appBar: AppBar(
                title: Text(_editing
                    ? 'Edit Damage Charge'
                    : 'Add Damage Charge')),
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
                              controller: _description,
                              label: 'Description',
                              maxLines: 3,
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                      ? 'Description is required.'
                                      : null),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                              controller: _amount,
                              label: 'Amount',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              validator: _amountValidator),
                          const SizedBox(height: AppSpacing.md),
                          BlocBuilder<SelectedStatusCubit, String>(
                            builder: (context, status) =>
                                DropdownButtonFormField<String>(
                              value: status,
                              decoration: const InputDecoration(
                                  labelText: 'Status'),
                              items: const ['pending', 'paid', 'waived']
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
                                BlocBuilder<DamageChargeCubit,
                                    DamageChargeState>(
                              builder: (context, state) => AppButton(
                                label: _editing
                                    ? 'Save Changes'
                                    : 'Add Damage Charge',
                                isLoading: submitting ||
                                    state is DamageChargeLoading,
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
