import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../cubit/tenant_cubit.dart';
import '../cubit/tenant_state.dart';
import '../widgets/tenant_form.dart';

class AddTenantPage extends StatelessWidget {
  const AddTenantPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<TenantCubit, TenantState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == TenantOperationStatus.loaded) {
          // Because creating -> loading -> loaded.
          // If we reach loaded and canPop, it means the operation succeeded.
          if (context.canPop()) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tenant added successfully.')),
            );
            context.pop(true);
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Add Tenant'),
          backgroundColor: AppColors.surface,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: TenantForm(
                  isEdit: false,
                  onSubmit: (tenant) {
                    context.read<TenantCubit>().createTenant(tenant);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
