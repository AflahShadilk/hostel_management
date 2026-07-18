import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dropdown_field.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../hostel/presentation/cubit/hostel_cubit.dart';
import '../../../room/domain/entities/bed_entity.dart';
import '../../domain/entities/tenant_entity.dart';
import '../../domain/entities/tenant_status.dart';
import '../cubit/tenant_cubit.dart';
import '../cubit/tenant_state.dart';
import 'bed_selection_widget.dart';

/// Shared form widget used by both [AddTenantPage] and [EditTenantPage].
///
/// [isEdit] controls whether the bed selection section is shown (Add only).
/// [initialTenant] pre-populates fields when editing.
/// [onSubmit] is called with the constructed [TenantEntity] on valid submit.
class TenantForm extends StatefulWidget {
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
  State<TenantForm> createState() => _TenantFormState();
}

class _TenantFormState extends State<TenantForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _emergencyNameController;
  late final TextEditingController _emergencyPhoneController;

  // Date state — driven by Cubit-safe approach: we store in local form state only.
  // These are form-display fields, not application state.
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  TenantStatus _selectedStatus = TenantStatus.active;
  BedEntity? _selectedBed;

  bool _submitted = false;
  // After first failed validation, fields auto-validate on interaction.
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

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
    _checkInDate = t?.checkInDate ?? DateTime.now();
    _checkOutDate = t?.checkOutDate;
    _selectedStatus = t?.status ?? TenantStatus.active;
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

  Future<void> _pickDate({required bool isCheckOut}) async {
    final now = DateTime.now();
    final initial = isCheckOut
        ? (_checkOutDate ?? _checkInDate ?? now)
        : (_checkInDate ?? now);
    final first = isCheckOut ? (_checkInDate ?? now) : DateTime(2000);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    if (isCheckOut) {
      _checkOutDate = picked;
    } else {
      _checkInDate = picked;
      // Clear check-out if it's now before check-in.
      if (_checkOutDate != null && _checkOutDate!.isBefore(picked)) {
        _checkOutDate = null;
      }
    }
    // Trigger rebuild for date label updates — this is safe local UI state.
    (context as Element).markNeedsBuild();
  }

  void _submit() {
    _submitted = true;

    if (!widget.isEdit && _selectedBed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a bed.'),
          backgroundColor: AppColors.error,
        ),
      );
      // Also trigger form validation to show field errors.
      _autovalidateMode = AutovalidateMode.onUserInteraction;
      _formKey.currentState?.validate();
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      _autovalidateMode = AutovalidateMode.onUserInteraction;
      return;
    }

    if (_checkInDate == null) {
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
        : _selectedBed!.id!;

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
      checkInDate: _checkInDate!,
      checkOutDate: _checkOutDate,
      status: _selectedStatus,
      createdAt: widget.initialTenant?.createdAt ?? now,
      updatedAt: now,
    );

    widget.onSubmit(tenant);
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';

  @override
  Widget build(BuildContext context) {
    final hostelId = context.read<HostelCubit>().state.hostel?.id;

    return BlocBuilder<TenantCubit, TenantState>(
      buildWhen: (prev, curr) => prev.status != curr.status,
      builder: (context, state) {
        final isSubmitting = state.status == TenantOperationStatus.creating ||
            state.status == TenantOperationStatus.updating;

        return Form(
          key: _formKey,
          autovalidateMode: _autovalidateMode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Personal Details ──────────────────────────────────────────
              _SectionHeader(label: 'Personal Details'),
              const SizedBox(height: AppSpacing.md),

              AppTextField(
                controller: _nameController,
                label: 'Full Name',
                prefixIcon: const Icon(Icons.person_outline),
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Full name is required.';
                  }
                  if (v.trim().length < 2) {
                    return 'Name must be at least 2 characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              AppTextField(
                controller: _phoneController,
                label: 'Phone Number',
                prefixIcon: const Icon(Icons.phone_outlined),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  final text = v?.trim() ?? '';
                  if (text.isEmpty) return 'Phone number is required.';
                  if (!RegExp(r'^\d{7,15}$').hasMatch(text)) {
                    return 'Enter a valid phone number (7–15 digits).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              AppTextField(
                controller: _emailController,
                label: 'Email (optional)',
                prefixIcon: const Icon(Icons.email_outlined),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  final text = v?.trim() ?? '';
                  if (text.isEmpty) return null; // optional
                  if (!RegExp(
                          r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
                      .hasMatch(text)) {
                    return 'Enter a valid email address.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              AppTextField(
                controller: _addressController,
                label: 'Address (optional)',
                prefixIcon: const Icon(Icons.home_outlined),
                maxLines: 2,
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Emergency Contact ─────────────────────────────────────────
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
                validator: (v) {
                  final text = v?.trim() ?? '';
                  if (text.isEmpty) return null; // optional
                  if (!RegExp(r'^\d{7,15}$').hasMatch(text)) {
                    return 'Enter a valid phone number (7–15 digits).';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Stay Details ──────────────────────────────────────────────
              _SectionHeader(label: 'Stay Details'),
              const SizedBox(height: AppSpacing.md),

              // Check-in date
              _DateField(
                label: 'Check-in Date',
                icon: Icons.calendar_today_outlined,
                date: _checkInDate,
                hint: 'Select check-in date',
                onTap: () => _pickDate(isCheckOut: false),
                formatDate: _formatDate,
              ),
              const SizedBox(height: AppSpacing.md),

              // Check-out date (optional)
              _DateField(
                label: 'Check-out Date (optional)',
                icon: Icons.event_available_outlined,
                date: _checkOutDate,
                hint: 'Select check-out date',
                onTap: () => _pickDate(isCheckOut: true),
                formatDate: _formatDate,
                trailing: _checkOutDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        tooltip: 'Clear',
                        onPressed: () {
                          _checkOutDate = null;
                          (context as Element).markNeedsBuild();
                        },
                      )
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // Status dropdown
              AppDropdownField<TenantStatus>(
                label: 'Status',
                value: _selectedStatus,
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
                onChanged: (s) {
                  if (s != null) _selectedStatus = s;
                },
              ),

              // ── Bed Selection (Add only) ──────────────────────────────────
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
                if (_submitted && _selectedBed == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Please select a bed.',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.error,
                          ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                if (hostelId != null)
                  BedSelectionWidget(
                    hostelId: hostelId,
                    selectedBed: _selectedBed,
                    onBedSelected: (bed) {
                      _selectedBed = bed;
                      (context as Element).markNeedsBuild();
                    },
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

              // ── Bed info (Edit read-only) ─────────────────────────────────
              if (widget.isEdit && widget.initialTenant != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _SectionHeader(label: 'Bed Assignment'),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bed_outlined,
                          size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Bed ID: ${widget.initialTenant!.bedId} — '
                          'Bed transfer is handled separately.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              AppButton(
                label: widget.isEdit ? 'Save Changes' : 'Assign Tenant',
                isLoading: isSubmitting,
                isFullWidth: true,
                onPressed: isSubmitting ? null : _submit,
              ),
            ],
          ),
        );
      },
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
