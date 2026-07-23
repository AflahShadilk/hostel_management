import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dashboard_ui.dart';
import '../../../../core/widgets/app_dropdown_field.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/utils/tenant_validators.dart';
import '../../../hostel/presentation/cubit/hostel_cubit.dart';
import '../../domain/entities/tenant_entity.dart';
import '../../domain/entities/tenant_status.dart';
import '../cubit/tenant_cubit.dart';
import '../cubit/tenant_form_cubit.dart';
import '../cubit/tenant_form_state.dart';
import '../cubit/tenant_state.dart';
import 'bed_selection_widget.dart';
import 'identity_document_picker.dart';

/// Shared form widget used by both [AddTenantPage] and [EditTenantPage].
///
/// UI state (dates, status, selected bed) is fully managed by [TenantFormCubit].
/// No setState() calls exist in this file.
///
/// [isEdit] controls whether the bed selection section is shown (Add only).
/// [initialTenant] pre-populates fields when editing.
/// [onSubmit] is called with the constructed [TenantEntity] on valid submit.
class TenantForm extends StatelessWidget {
  final TenantEntity? initialTenant;
  final bool isEdit;
  final void Function(TenantEntity tenant) onSubmit;

  const TenantForm({
    super.key,
    this.initialTenant,
    this.isEdit = false,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TenantFormCubit(
        initialCheckIn: initialTenant?.checkInDate ?? DateTime.now(),
        initialCheckOut: initialTenant?.checkOutDate,
        initialStatus: initialTenant?.status ?? TenantStatus.active,
      ),
      child: _TenantFormBody(
        initialTenant: initialTenant,
        isEdit: isEdit,
        onSubmit: onSubmit,
      ),
    );
  }
}

class _TenantFormBody extends StatefulWidget {
  final TenantEntity? initialTenant;
  final bool isEdit;
  final void Function(TenantEntity tenant) onSubmit;

  const _TenantFormBody({
    required this.initialTenant,
    required this.isEdit,
    required this.onSubmit,
  });

  @override
  State<_TenantFormBody> createState() => _TenantFormBodyState();
}

class _TenantFormBodyState extends State<_TenantFormBody> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _emergencyNameController;
  late final TextEditingController _emergencyPhoneController;

  bool _submitted = false;
  // autovalidateMode is derived from TenantFormCubit.showValidationErrors — no setState needed.

  @override
  void initState() {
    super.initState();
    final t = widget.initialTenant;
    _nameController = TextEditingController(text: t?.fullName ?? '');
    _phoneController = TextEditingController(text: t?.phoneNumber ?? '');
    _emailController = TextEditingController(text: t?.email ?? '');
    _addressController = TextEditingController(text: t?.address ?? '');
    _emergencyNameController =
        TextEditingController(text: t?.emergencyContactName ?? '');
    _emergencyPhoneController =
        TextEditingController(text: t?.emergencyContactPhone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context,
      {required bool isCheckOut}) async {
    final formState = context.read<TenantFormCubit>().state;
    final now = DateTime.now();
    final initial = isCheckOut
        ? (formState.checkOutDate ?? formState.checkInDate ?? now)
        : (formState.checkInDate ?? now);
    final first = isCheckOut ? (formState.checkInDate ?? now) : DateTime(2000);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    if (!context.mounted) return;
    final cubit = context.read<TenantFormCubit>();
    if (isCheckOut) {
      cubit.updateCheckOutDate(picked);
    } else {
      cubit.updateCheckInDate(picked);
    }
  }

  void _submit(BuildContext context) {
    _submitted = true;
    final formState = context.read<TenantFormCubit>().state;

    if (!widget.isEdit && formState.selectedBed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a bed.'),
          backgroundColor: AppColors.error,
        ),
      );
      context.read<TenantFormCubit>().enableValidation();
      _formKey.currentState?.validate();
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      context.read<TenantFormCubit>().enableValidation();
      return;
    }

    if (formState.checkInDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a check-in date.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final bedId = widget.isEdit
        ? widget.initialTenant!.bedId
        : formState.selectedBed!.id!;

    final tenant = TenantEntity(
      id: widget.initialTenant?.id,
      bedId: bedId,
      fullName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      emergencyContactName: _emergencyNameController.text.trim().isEmpty
          ? null
          : _emergencyNameController.text.trim(),
      emergencyContactPhone: _emergencyPhoneController.text.trim().isEmpty
          ? null
          : _emergencyPhoneController.text.trim(),
      idType: formState.selectedIdType,
      idDocumentPath: formState.idDocumentPath,
      checkInDate: formState.checkInDate!,
      checkOutDate: formState.checkOutDate,
      status: formState.status,
      createdAt: widget.initialTenant?.createdAt ?? now,
      updatedAt: now,
    );

    widget.onSubmit(tenant);
  }

  String _formatDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';

  @override
  Widget build(BuildContext context) {
    final hostelId = context.read<HostelCubit>().state.hostel?.id;

    return BlocBuilder<TenantCubit, TenantState>(
      buildWhen: (prev, curr) => prev.status != curr.status,
      builder: (context, tenantState) {
        final isSubmitting =
            tenantState.status == TenantOperationStatus.creating ||
                tenantState.status == TenantOperationStatus.updating;

        return BlocBuilder<TenantFormCubit, TenantFormState>(
          builder: (context, formState) {
            final autovalidateMode = formState.showValidationErrors
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled;
            return Form(
              key: _formKey,
              autovalidateMode: autovalidateMode,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Personal Details ───────────────────────────────────────
                  _SectionHeader(label: 'Personal Details'),
                  const SizedBox(height: AppSpacing.md),

                  AppTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    prefixIcon: const Icon(Icons.person_outline),
                    textInputAction: TextInputAction.next,
                    validator: TenantValidators.validateName,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  AppTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: TenantValidators.validatePhone,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  AppTextField(
                    controller: _emailController,
                    label: 'Email (optional)',
                    prefixIcon: const Icon(Icons.email_outlined),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: TenantValidators.validateEmail,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  AppTextField(
                    controller: _addressController,
                    label: 'Address (optional)',
                    prefixIcon: const Icon(Icons.home_outlined),
                    maxLines: 2,
                    textInputAction: TextInputAction.next,
                    validator: TenantValidators.validateAddress,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Emergency Contact ──────────────────────────────────────
                  _SectionHeader(label: 'Emergency Contact (optional)'),
                  const SizedBox(height: AppSpacing.md),

                  AppTextField(
                    controller: _emergencyNameController,
                    label: 'Contact Name',
                    prefixIcon: const Icon(Icons.contact_emergency_outlined),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  AppTextField(
                    controller: _emergencyPhoneController,
                    label: 'Contact Phone',
                    prefixIcon: const Icon(Icons.phone_in_talk_outlined),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: TenantValidators.validateEmergencyPhone,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Identity Proof ─────────────────────────────────────────
                  _SectionHeader(label: 'Identity Proof (optional)'),
                  const SizedBox(height: AppSpacing.md),
                  const IdentityDocumentPicker(),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Stay Details ───────────────────────────────────────────
                  _SectionHeader(label: 'Stay Details'),
                  const SizedBox(height: AppSpacing.md),

                  // Check-in date — driven by TenantFormCubit state
                  _DateField(
                    label: 'Check-in Date',
                    icon: Icons.calendar_today_outlined,
                    date: formState.checkInDate,
                    hint: 'Select check-in date',
                    onTap: () => _pickDate(context, isCheckOut: false),
                    formatDate: _formatDate,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Check-out date (optional) — driven by TenantFormCubit state
                  _DateField(
                    label: 'Check-out Date (optional)',
                    icon: Icons.event_available_outlined,
                    date: formState.checkOutDate,
                    hint: 'Select check-out date',
                    onTap: () => _pickDate(context, isCheckOut: true),
                    formatDate: _formatDate,
                    trailing: formState.checkOutDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            tooltip: 'Clear',
                            onPressed: () => context
                                .read<TenantFormCubit>()
                                .updateCheckOutDate(null),
                          )
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Status dropdown — driven by TenantFormCubit state
                  AppDropdownField<TenantStatus>(
                    label: 'Status',
                    value: formState.status,
                    items: TenantStatus.values,
                    itemLabelBuilder: (s) {
                      switch (s) {
                        case TenantStatus.active:
                          return 'Active';
                        case TenantStatus.checkedOut:
                          return 'Checked Out';
                        case TenantStatus.inactive:
                          return 'Inactive';
                      }
                    },
                    onChanged: null,
                  ),

                  // ── Bed Selection (Add only) ───────────────────────────────
                  if (!widget.isEdit) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _SectionHeader(label: 'Bed Assignment'),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Select a vacant bed to assign this tenant.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    if (_submitted && formState.selectedBed == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Please select a bed.',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.error,
                                  ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.md),
                    if (hostelId != null)
                      BedSelectionWidget(
                        hostelId: hostelId,
                        selectedBed: formState.selectedBed,
                        onBedSelected: (bed) => context
                            .read<TenantFormCubit>()
                            .updateSelectedBed(bed),
                      )
                    else
                      Text(
                        'Hostel not configured.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.error),
                      ),
                  ],

                  // ── Bed info (Edit read-only) ──────────────────────────────
                  if (widget.isEdit && widget.initialTenant != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _SectionHeader(label: 'Bed Assignment'),
                    const SizedBox(height: AppSpacing.sm),
                    _CurrentBedInfo(
                      bedId: widget.initialTenant!.bedId,
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xl),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 80.0),
                    child: AppButton(
                      label: widget.isEdit ? 'Save Changes' : 'Assign Tenant',
                      isLoading: isSubmitting,
                      isFullWidth: true,
                      onPressed: isSubmitting ? null : () => _submit(context),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Current bed info widget — resolves room/bed name through repository
// ─────────────────────────────────────────────────────────────────────────────

/// Shows the resolved room and bed name for the edit form.
/// Uses BedSelectionCubit to query names — no direct repository access in widget.
class _CurrentBedInfo extends StatelessWidget {
  final int? bedId;
  const _CurrentBedInfo({required this.bedId});

  @override
  Widget build(BuildContext context) {
    return AppDashboardCard(
      child: Row(
        children: [
          const Icon(Icons.bed_outlined,
              size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Current bed — use Transfer to change assignment.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Supporting widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final IconData icon;
  final DateTime? date;
  final String hint;
  final VoidCallback onTap;
  final String Function(DateTime) formatDate;
  final Widget? trailing;

  const _DateField({
    required this.label,
    required this.icon,
    required this.date,
    required this.hint,
    required this.onTap,
    required this.formatDate,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: trailing,
        ),
        child: Text(
          date != null ? formatDate(date!) : hint,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: date != null
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
        ),
      ),
    );
  }
}
