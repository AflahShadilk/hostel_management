import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/hostel_cubit.dart';
import '../cubit/hostel_state.dart';
import '../cubit/hostel_status.dart';

class HostelProfilePage extends StatefulWidget {
  const HostelProfilePage({super.key});

  @override
  State<HostelProfilePage> createState() => _HostelProfilePageState();
}

class _HostelProfilePageState extends State<HostelProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _gstController = TextEditingController();
  final _websiteController = TextEditingController();

  bool _isEditing = false;
  File? _selectedLogo;
  String? _existingLogoPath;

  // The hostel loaded when the page was last committed to view mode.
  late HostelState _lastConfiguredState;

  @override
  void initState() {
    super.initState();
    _lastConfiguredState = context.read<HostelCubit>().state;
    final hostel = _lastConfiguredState.hostel;
    if (hostel != null) {
      _populateFrom(hostel);
    }
  }

  void _populateFrom(hostelEntity) {
    _nameController.text = hostelEntity.name;
    _addressController.text = hostelEntity.address;
    _phoneController.text = hostelEntity.phone;
    _emailController.text = hostelEntity.email ?? '';
    _ownerNameController.text = hostelEntity.ownerName;
    _gstController.text = hostelEntity.gstNumber ?? '';
    _websiteController.text = hostelEntity.website ?? '';
    _existingLogoPath = hostelEntity.logoPath;
    _selectedLogo = null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _ownerNameController.dispose();
    _gstController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _enterEditMode() => setState(() => _isEditing = true);

  void _cancelEdit() {
    final hostel = context.read<HostelCubit>().state.hostel;
    if (hostel != null) _populateFrom(hostel);
    setState(() {
      _isEditing = false;
      _selectedLogo = null;
    });
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() => _selectedLogo = File(result.files.single.path!));
    }
  }

  void _save(BuildContext context) {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final cubit = context.read<HostelCubit>();
    final hostel = cubit.state.hostel;
    final logoPath = _selectedLogo?.path ?? _existingLogoPath;

    if (hostel == null) {
      // Create mode (notConfigured state)
      final authState = context.read<AuthCubit>().state;
      final user = authState.user;
      if (user == null || user.id == null || user.id! <= 0) return;

      cubit.createHostel(
        name: _nameController.text,
        address: _addressController.text,
        phone: _phoneController.text,
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text,
        ownerName: _ownerNameController.text,
        gstNumber: _gstController.text.trim().isEmpty
            ? null
            : _gstController.text,
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text,
        logoPath: logoPath,
        ownerUserId: user.id!,
      );
    } else {
      cubit.updateHostel(
        hostel: hostel,
        name: _nameController.text,
        address: _addressController.text,
        phone: _phoneController.text,
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text,
        ownerName: _ownerNameController.text,
        gstNumber: _gstController.text.trim().isEmpty
            ? null
            : _gstController.text,
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text,
        logoPath: logoPath,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Validators
  // ---------------------------------------------------------------------------

  static String? _validateRequired(String? v, String msg) =>
      (v == null || v.trim().isEmpty) ? msg : null;

  static String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter a phone number.';
    final d = v.trim().replaceFirst('+', '');
    if (d.isEmpty || int.tryParse(d) == null) {
      return 'Please enter a valid phone number.';
    }
    if (d.length < 6 || d.length > 15) return 'Please enter a valid phone number.';
    return null;
  }

  static String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return BlocListener<HostelCubit, HostelState>(
      listenWhen: (p, c) => p.status != c.status,
      listener: (context, state) {
        if (state.status == HostelStatus.failure && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
        } else if (state.status == HostelStatus.configured) {
          final hostel = state.hostel;
          if (hostel != null) _populateFrom(hostel);
          setState(() => _isEditing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hostel profile saved successfully.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Hostel Profile'),
        ),
        body: BlocBuilder<HostelCubit, HostelState>(
          builder: (context, state) {
            if (state.status == HostelStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            final hostel = state.hostel;

            if (hostel == null && !_isEditing) {
              return _EmptyState(onCreateTap: _enterEditMode);
            }

            return _isEditing
                ? _buildEditForm(context, state)
                : _buildViewProfile(context, state);
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // View Mode
  // ---------------------------------------------------------------------------

  Widget _buildViewProfile(BuildContext context, HostelState state) {
    final hostel = state.hostel!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasLogo = (hostel.logoPath != null && hostel.logoPath!.isNotEmpty);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colorScheme.outlineVariant),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x140F172A),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primaryContainer,
                    border: Border.all(
                      color: colorScheme.surfaceContainerLowest,
                      width: 3,
                    ),
                    image: hasLogo
                        ? DecorationImage(
                            image: FileImage(File(hostel.logoPath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: !hasLogo
                      ? Icon(
                          Icons.apartment_rounded,
                          size: 38,
                          color: colorScheme.onPrimaryContainer,
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hostel.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        hostel.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              hostel.phone,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: _enterEditMode,
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Edit Profile'),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionCard(
            title: 'Contact Information',
            icon: Icons.contacts_rounded,
            children: [
              _InfoRow(
                icon: Icons.location_on_outlined,
                label: 'Address',
                value: hostel.address,
              ),
              _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: hostel.phone,
              ),
              if (hostel.email != null && hostel.email!.isNotEmpty)
                _InfoRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: hostel.email!,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: 'Owner Information',
            icon: Icons.person_rounded,
            children: [
              _InfoRow(
                icon: Icons.badge_outlined,
                label: 'Owner Name',
                value: hostel.ownerName,
              ),
            ],
          ),
          if ((hostel.gstNumber?.isNotEmpty ?? false) ||
              (hostel.website?.isNotEmpty ?? false)) ...[
            const SizedBox(height: AppSpacing.md),
            _SectionCard(
              title: 'Business Information',
              icon: Icons.business_center_outlined,
              children: [
                if (hostel.gstNumber?.isNotEmpty ?? false)
                  _InfoRow(
                    icon: Icons.receipt_long_outlined,
                    label: 'GST',
                    value: hostel.gstNumber!,
                  ),
                if (hostel.website?.isNotEmpty ?? false)
                  _InfoRow(
                    icon: Icons.language_outlined,
                    label: 'Website',
                    value: hostel.website!,
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Edit Form
  // ---------------------------------------------------------------------------

  Widget _buildEditForm(BuildContext context, HostelState state) {
    final hasLogo =
        _selectedLogo != null || (_existingLogoPath?.isNotEmpty ?? false);

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ----------------------------------------------------------------
            // Logo picker
            // ----------------------------------------------------------------
            Center(
              child: GestureDetector(
                onTap: _pickLogo,
                child: Stack(
                  children: [
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primaryContainer,
                        border: Border.all(
                          color: AppColors.border,
                          width: 2,
                        ),
                        image: _selectedLogo != null
                            ? DecorationImage(
                                image: FileImage(_selectedLogo!),
                                fit: BoxFit.cover,
                              )
                            : (_existingLogoPath != null &&
                                    _existingLogoPath!.isNotEmpty)
                                ? DecorationImage(
                                    image: FileImage(
                                        File(_existingLogoPath!)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                      ),
                      child: !hasLogo
                          ? Icon(
                              Icons.apartment_rounded,
                              size: 44,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.background,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Tap to change logo',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ----------------------------------------------------------------
            // Required Fields
            // ----------------------------------------------------------------
            _FormSection(
              title: 'Hostel Details',
              children: [
                AppTextField(
                  controller: _nameController,
                  label: 'Hostel Name',
                  prefixIcon: const Icon(Icons.apartment_rounded),
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      _validateRequired(v, 'Please enter the hostel name.'),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _addressController,
                  label: 'Address',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  textInputAction: TextInputAction.next,
                  maxLines: 2,
                  validator: (v) =>
                      _validateRequired(v, 'Please enter the hostel address.'),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: _validatePhone,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            _FormSection(
              title: 'Owner Details',
              children: [
                AppTextField(
                  controller: _ownerNameController,
                  label: 'Owner Name',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      _validateRequired(v, 'Please enter the owner name.'),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            _FormSection(
              title: 'Optional Details',
              children: [
                AppTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  prefixIcon: const Icon(Icons.email_outlined),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: _validateEmail,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _gstController,
                  label: 'GST Number',
                  prefixIcon: const Icon(Icons.receipt_long_outlined),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _websiteController,
                  label: 'Website',
                  prefixIcon: const Icon(Icons.language_outlined),
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // ----------------------------------------------------------------
            // Action Buttons
            // ----------------------------------------------------------------
            BlocSelector<HostelCubit, HostelState, bool>(
              selector: (s) => s.status == HostelStatus.saving,
              builder: (context, isSaving) {
                return Row(
                  children: [
                    if (context.read<HostelCubit>().state.hostel != null) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isSaving ? null : _cancelEdit,
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                    ],
                    Expanded(
                      flex: 2,
                      child: AppButton(
                        label: isSaving ? 'Saving…' : 'Save Profile',
                        isLoading: isSaving,
                        isFullWidth: true,
                        icon: Icons.save_rounded,
                        onPressed: isSaving ? null : () => _save(context),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty State
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateTap;

  const _EmptyState({required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.secondaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                Icons.apartment_rounded,
                size: 48,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No Hostel Profile Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Create your hostel profile to display business information across receipts, reports, and more.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Create Hostel Profile',
              icon: Icons.add_business_rounded,
              onPressed: onCreateTap,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section Card
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: AppSpacing.sm),
            ...children,
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info Row
// ---------------------------------------------------------------------------

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Form Section (card-style grouping for edit mode)
// ---------------------------------------------------------------------------

class _FormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _FormSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}
