import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/tenant_entity.dart';
import '../../../communication/domain/repositories/communication_repository.dart';
import '../cubit/tenant_cubit.dart';
import '../cubit/tenant_state.dart';
import '../models/tenant_view_model.dart';
import '../widgets/tenant_card.dart';

/// Tenant list page.
///
/// No setState() calls. Search active/inactive state is managed by [TenantCubit].
/// Room and bed names are resolved by [TenantCubit] at load time and exposed
/// as [TenantViewModel] objects — widgets only render them.
class TenantManagementPage extends StatefulWidget {
  const TenantManagementPage({super.key});

  @override
  State<TenantManagementPage> createState() => _TenantManagementPageState();
}

class _TenantManagementPageState extends State<TenantManagementPage> {
  final _searchController = TextEditingController();
  bool _loadTriggered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_loadTriggered) {
        _loadTriggered = true;
        _triggerLoad();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _triggerLoad() {
    context.read<TenantCubit>().loadTenants();
  }

  void _navigateToAddTenant(BuildContext context) {
    context.pushNamed(AppRoutes.addTenantName).then((changed) {
      if (changed == true && mounted) _triggerLoad();
    });
  }

  void _navigateToEditTenant(BuildContext context, TenantEntity tenant) {
    context
        .pushNamed(
      AppRoutes.editTenantName,
      pathParameters: {'tenantId': tenant.id!.toString()},
      extra: tenant,
    )
        .then((changed) {
      if (changed == true && mounted) _triggerLoad();
    });
  }

  void _navigateToTransferTenant(BuildContext context, TenantEntity tenant) {
    context
        .pushNamed(
      AppRoutes.transferTenantName,
      pathParameters: {'tenantId': tenant.id!.toString()},
      extra: tenant,
    )
        .then((changed) {
      if (changed == true && mounted) _triggerLoad();
    });
  }

  Future<void> _runCommunication(Future<CommunicationResult> action) async {
    final result = await action;
    if (!mounted || result.isSuccess) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message ?? 'Communication action failed.')),
    );
  }

  void _contactTenant(TenantEntity tenant, _TenantContactAction action) {
    final communication = getIt<CommunicationRepository>();
    switch (action) {
      case _TenantContactAction.whatsApp:
        _runCommunication(communication.openWhatsAppChat(tenant.phoneNumber));
      case _TenantContactAction.callTenant:
        _runCommunication(communication.makePhoneCall(tenant.phoneNumber));
      case _TenantContactAction.callGuardian:
        final guardianPhone = tenant.emergencyContactPhone;
        if (guardianPhone == null || guardianPhone.trim().isEmpty) return;
        _runCommunication(communication.makePhoneCall(guardianPhone));
      case _TenantContactAction.sms:
        _runCommunication(communication.sendSms(
          tenant.phoneNumber,
          'Hello ${tenant.fullName}, this is a message from Hostel Management.',
        ));
    }
  }

  Future<void> _confirmDelete(BuildContext context, TenantEntity tenant) async {
    final tenantCubit = context.read<TenantCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Tenant?'),
        content: Text(
          'Deleting ${tenant.fullName} will also vacate their bed. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && tenant.id != null) {
      tenantCubit.deleteTenant(tenant.id!, bedId: tenant.bedId);
    }
  }

  Future<void> _confirmCheckOut(
      BuildContext context, TenantEntity tenant) async {
    final tenantCubit = context.read<TenantCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Check Out Tenant?'),
        content: Text(
          'Checking out ${tenant.fullName} will release their bed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.warning),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Check Out'),
          ),
        ],
      ),
    );
    if (confirmed == true && tenant.id != null && tenant.bedId != null) {
      tenantCubit.checkOutTenant(tenant.id!, bedId: tenant.bedId!);
    }
  }

  int _columnCount(double width) {
    if (width >= 900) return 3;
    if (width >= 600) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TenantCubit, TenantState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == TenantOperationStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final isSearchActive = state.isSearchActive;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Tenants'),
            actions: [
              IconButton(
                icon: Icon(isSearchActive ? Icons.close : Icons.search),
                tooltip: isSearchActive ? 'Close search' : 'Search tenants',
                onPressed: () {
                  final cubit = context.read<TenantCubit>();
                  if (isSearchActive) {
                    _searchController.clear();
                    cubit.search('');
                  }
                  cubit.setSearchActive(!isSearchActive);
                },
              ),
            ],
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 80.0),
            child: FloatingActionButton(
              onPressed: () => _navigateToAddTenant(context),
              tooltip: 'Add Tenant',
              child: const Icon(Icons.add),
            ),
          ),
          body: Column(
            children: [
              if (isSearchActive)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.xs,
                  ),
                  child: AppTextField(
                    controller: _searchController,
                    hint: 'Search by name, phone, room, bed...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              context.read<TenantCubit>().search('');
                            },
                          )
                        : null,
                    onChanged: (query) =>
                        context.read<TenantCubit>().search(query),
                  ),
                ),
              Expanded(child: _buildBody(context, state)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, TenantState state) {
    if (state.status == TenantOperationStatus.loading &&
        state.viewModels.isEmpty) {
      return const Center(child: AppLoadingIndicator());
    }

    if (state.status == TenantOperationStatus.failure &&
        state.viewModels.isEmpty) {
      return AppEmptyState(
        icon: Icons.error_outline,
        title: 'Unable to load tenants',
        message: state.errorMessage ?? 'Something went wrong.',
        action: AppButton(
          label: 'Retry',
          onPressed: _triggerLoad,
        ),
      );
    }

    if (state.viewModels.isEmpty) {
      return AppEmptyState(
        icon: Icons.people_outline,
        title: 'No tenants yet',
        message: 'Add your first tenant to start managing occupancy.',
        action: AppButton(
          label: 'Add Tenant',
          icon: Icons.add,
          onPressed: () => _navigateToAddTenant(context),
        ),
      );
    }

    final displayVMs =
        state.isSearchActive ? state.filteredViewModels : state.viewModels;

    if (displayVMs.isEmpty && state.isSearchActive) {
      return AppEmptyState(
        icon: Icons.search_off,
        title: 'No results found',
        message: 'No tenants match your search query.',
        action: AppButton(
          label: 'Clear Search',
          onPressed: () {
            _searchController.clear();
            context.read<TenantCubit>().search('');
            context.read<TenantCubit>().setSearchActive(false);
          },
        ),
      );
    }

    final isMutating = state.status == TenantOperationStatus.creating ||
        state.status == TenantOperationStatus.updating ||
        state.status == TenantOperationStatus.deleting ||
        state.status == TenantOperationStatus.checkingOut ||
        state.status == TenantOperationStatus.transferring;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnCount(constraints.maxWidth);
        return RefreshIndicator(
          onRefresh: () async {
            await context.read<TenantCubit>().loadTenants();
          },
          child: columns == 1
              ? _buildList(context, displayVMs, isMutating)
              : _buildGrid(context, displayVMs, isMutating, columns),
        );
      },
    );
  }

  Widget _buildList(
      BuildContext context, List<TenantViewModel> viewModels, bool isMutating) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: viewModels.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final vm = viewModels[index];
        return TenantCard(
          tenant: vm.tenant,
          roomLabel: vm.roomName,
          bedLabel: vm.bedName,
          actionsEnabled: !isMutating,
          onCheckOut: () => _confirmCheckOut(context, vm.tenant),
          onTransfer: () => _navigateToTransferTenant(context, vm.tenant),
          onEdit: () => _navigateToEditTenant(context, vm.tenant),
          onDelete: () => _confirmDelete(context, vm.tenant),
          onWhatsApp: () =>
              _contactTenant(vm.tenant, _TenantContactAction.whatsApp),
          onCallTenant: () =>
              _contactTenant(vm.tenant, _TenantContactAction.callTenant),
          onCallGuardian: vm.tenant.emergencyContactPhone?.trim().isNotEmpty ==
                  true
              ? () =>
                  _contactTenant(vm.tenant, _TenantContactAction.callGuardian)
              : null,
          onSms: () => _contactTenant(vm.tenant, _TenantContactAction.sms),
        );
      },
    );
  }

  Widget _buildGrid(BuildContext context, List<TenantViewModel> viewModels,
      bool isMutating, int columns) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.2,
      ),
      itemCount: viewModels.length,
      itemBuilder: (context, index) {
        final vm = viewModels[index];
        return TenantCard(
          tenant: vm.tenant,
          roomLabel: vm.roomName,
          bedLabel: vm.bedName,
          actionsEnabled: !isMutating,
          onCheckOut: () => _confirmCheckOut(context, vm.tenant),
          onTransfer: () => _navigateToTransferTenant(context, vm.tenant),
          onEdit: () => _navigateToEditTenant(context, vm.tenant),
          onDelete: () => _confirmDelete(context, vm.tenant),
          onWhatsApp: () =>
              _contactTenant(vm.tenant, _TenantContactAction.whatsApp),
          onCallTenant: () =>
              _contactTenant(vm.tenant, _TenantContactAction.callTenant),
          onCallGuardian: vm.tenant.emergencyContactPhone?.trim().isNotEmpty ==
                  true
              ? () =>
                  _contactTenant(vm.tenant, _TenantContactAction.callGuardian)
              : null,
          onSms: () => _contactTenant(vm.tenant, _TenantContactAction.sms),
        );
      },
    );
  }
}

enum _TenantContactAction { whatsApp, callTenant, callGuardian, sms }
