import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/tenant_entity.dart';
import '../cubit/tenant_cubit.dart';
import '../cubit/tenant_state.dart';
import '../widgets/tenant_form.dart';

class EditTenantPage extends StatelessWidget {
  final TenantEntity? tenant;

  const EditTenantPage({super.key, required this.tenant});

  @override
  Widget build(BuildContext context) {
    if (tenant == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Tenant')),
        body: const Center(child: Text('Tenant data not found.')),
      );
    }

    return BlocListener<TenantCubit, TenantState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == TenantOperationStatus.loaded) {
          // Because updating -> loading -> loaded.
          if (context.canPop()) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tenant updated successfully.')),
            );
            context.pop(true);
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Edit Tenant'),
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
                  isEdit: true,
                  initialTenant: tenant,
                  onSubmit: (updatedTenant) {
                    context.read<TenantCubit>().updateTenant(updatedTenant);
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
