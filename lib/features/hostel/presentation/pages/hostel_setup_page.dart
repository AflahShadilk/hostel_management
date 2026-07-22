import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

import '../cubit/hostel_cubit.dart';
import '../cubit/hostel_state.dart';
import '../cubit/hostel_status.dart';

/// Initial hostel configuration page shown to a new Owner after PIN setup,
/// or to a returning Owner who has not yet completed hostel setup.
///
/// Flow:
///   HostelSetupPage
///   → HostelCubit.createHostel()
///   → HostelRepository
///   → SQLite
///
/// Navigation is outbound-only: the page has no back arrow and uses
/// replacement navigation on success so it never appears in the back stack.
class HostelSetupPage extends StatefulWidget {
  const HostelSetupPage({super.key});

  @override
  State<HostelSetupPage> createState() => _HostelSetupPageState();
}

class _HostelSetupPageState extends State<HostelSetupPage> {
  final _formKey = GlobalKey<FormState>();

  final _hostelNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _ownerNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Prefill owner-related fields from the authenticated session once,
    // safely, without calling setState().
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthCubit>().state;
      final user = authState.user;
      if (user != null && user.role == UserRole.owner) {
        _ownerNameController.text = user.name;
        _phoneController.text = user.phone;
        _emailController.text = user.email;
      }
    });
  }

  @override
  void dispose() {
    _hostelNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _ownerNameController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Submission
  // ---------------------------------------------------------------------------

  void _submit(BuildContext context) {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Confirm authenticated owner context before calling the cubit.
    final authState = context.read<AuthCubit>().state;
    final user = authState.user;

    if (user == null ||
        user.role != UserRole.owner ||
        user.id == null ||
        user.id! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to identify the owner account. Please sign in again.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    context.read<HostelCubit>().createHostel(
          name: _hostelNameController.text,
          logoPath: null, // Image picker will be added in a future task.
          address: _addressController.text,
          phone: _phoneController.text,
          email: _emailController.text,
          ownerName: _ownerNameController.text,
          ownerUserId: user.id!,
        );
  }

  // ---------------------------------------------------------------------------
  // Validators
  // ---------------------------------------------------------------------------

  static String? _validateRequired(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a phone number.';
    }
    // Allows an optional leading + followed by 6-15 digits.
    final digits = value.trim().replaceFirst('+', '');
    if (digits.isEmpty || int.tryParse(digits) == null) {
      return 'Please enter a valid phone number.';
    }
    if (digits.length < 6 || digits.length > 15) {
      return 'Please enter a valid phone number.';
    }
    return null;
  }

  static String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter an email address.';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
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
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == HostelStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
        } else if (state.status == HostelStatus.configured) {
          // Hostel is now configured — navigate to Home, replacing setup page.
          context.goNamed(AppRoutes.homeName);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Set Up Your Hostel'),
          automaticallyImplyLeading: false, // No back to incomplete flow.
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              // Centred on tablets with a sensible max width.
              constraints: const BoxConstraints(maxWidth: 680),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.lg,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --------------------------------------------------------
                      // Header
                      // --------------------------------------------------------
                      const Icon(
                        Icons.apartment_rounded,
                        size: 56,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Set up your hostel',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Add your hostel details to complete your account setup.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // --------------------------------------------------------
                      // Hostel Name
                      // --------------------------------------------------------
                      AppTextField(
                        controller: _hostelNameController,
                        label: 'Hostel Name',
                        prefixIcon: const Icon(Icons.business_rounded),
                        textInputAction: TextInputAction.next,
                        validator: (value) => _validateRequired(
                            value, 'Please enter the hostel name.'),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // --------------------------------------------------------
                      // Logo Placeholder
                      // --------------------------------------------------------
                      _LogoPlaceholder(),

                      const SizedBox(height: AppSpacing.lg),

                      // --------------------------------------------------------
                      // Address
                      // --------------------------------------------------------
                      AppTextField(
                        controller: _addressController,
                        label: 'Address',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        maxLines: 3,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.streetAddress,
                        validator: (value) => _validateRequired(
                            value, 'Please enter the hostel address.'),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // --------------------------------------------------------
                      // Phone Number
                      // --------------------------------------------------------
                      AppTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        validator: _validatePhone,
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // --------------------------------------------------------
                      // Email Address
                      // --------------------------------------------------------
                      AppTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        prefixIcon: const Icon(Icons.email_outlined),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: _validateEmail,
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // --------------------------------------------------------
                      // Owner Name
                      // --------------------------------------------------------
                      AppTextField(
                        controller: _ownerNameController,
                        label: 'Owner Name',
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        textInputAction: TextInputAction.done,
                        validator: (value) => _validateRequired(
                            value, 'Please enter the owner name.'),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // --------------------------------------------------------
                      // Complete Setup Button
                      // --------------------------------------------------------
                      BlocSelector<HostelCubit, HostelState, bool>(
                        selector: (state) =>
                            state.status == HostelStatus.saving,
                        builder: (context, isSaving) {
                          return AppButton(
                            label: 'Complete Setup',
                            isLoading: isSaving,
                            isFullWidth: true,
                            onPressed: isSaving ? null : () => _submit(context),
                          );
                        },
                      ),

                      const SizedBox(height: AppSpacing.md),

                      Text(
                        'You can update these details later in Hostel Settings.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppSpacing.lg),
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

// ---------------------------------------------------------------------------
// Logo Placeholder Widget
// ---------------------------------------------------------------------------

/// Informational placeholder for the future logo picker.
/// Passes logoPath: null during hostel creation — no fake paths are created.
class _LogoPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.apartment_rounded,
              size: 36,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Hostel Logo',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Optional · Logo selection coming soon',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
