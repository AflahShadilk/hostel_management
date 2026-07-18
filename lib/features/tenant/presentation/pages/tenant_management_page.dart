// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../room/presentation/cubit/room_cubit.dart';
import '../../domain/entities/tenant_entity.dart';
import '../cubit/tenant_cubit.dart';
import '../cubit/tenant_state.dart';
import '../widgets/tenant_card.dart';

class TenantManagementPage extends StatefulWidget {
  const TenantManagementPage({super.key});

  @override
  State<TenantManagementPage> createState() => _TenantManagementPageState();
}

class _TenantManagementPageState extends State<TenantManagementPage> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
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
    context.pushNamed(
      AppRoutes.editTenantName,
      pathParameters: {'tenantId': tenant.id!.toString()},
      extra: tenant,
    ).then((changed) {
      if (changed == true && mounted) _triggerLoad();
    });
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

  int _columnCount(double width) {
    if (width >= 900) return 3;
    if (width >= 600) return 2;
    return 1;
  }

  /// Resolves room and bed strings from the RoomCubit state.
  _ResolvedBed _resolveBed(BuildContext context, int bedId) {
    final rooms = context.read<RoomCubit>().state.rooms;
    for (final room in rooms) {
      // NOTE: RoomEntity does not contain its beds in this architecture.
      // We will need to query the BedRepository directly if we need the bed number.
      // However, we don't want to do that synchronously in build.
      // For now, we will return the bed ID.
    }
    return _ResolvedBed('Unknown', 'ID: $bedId');
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
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search by name, phone, email...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.white70),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (query) =>
                        context.read<TenantCubit>().search(query),
                  )
                : const Text('Tenants'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(_isSearching ? Icons.close : Icons.search),
                tooltip: _isSearching ? 'Close search' : 'Search tenants',
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                      context.read<TenantCubit>().search('');
                    }
                  });
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _navigateToAddTenant(context),
            tooltip: 'Add Tenant',
            child: const Icon(Icons.add),
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, TenantState state) {
    if (state.status == TenantOperationStatus.loading &&
        state.tenants.isEmpty) {
      return const Center(child: AppLoadingIndicator());
    }

    if (state.status == TenantOperationStatus.failure &&
        state.tenants.isEmpty) {
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

    if (state.tenants.isEmpty) {
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

    final displayTenants =
        _isSearching ? state.filteredTenants : state.tenants;

    if (displayTenants.isEmpty && _isSearching) {
      return AppEmptyState(
        icon: Icons.search_off,
        title: 'No results found',
        message: 'No tenants match your search query.',
        action: AppButton(
          label: 'Clear Search',
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchController.clear();
              context.read<TenantCubit>().search('');
            });
          },
        ),
      );
    }

    final isMutating = state.status == TenantOperationStatus.creating ||
        state.status == TenantOperationStatus.updating ||
        state.status == TenantOperationStatus.deleting ||
        state.status == TenantOperationStatus.checkingOut;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnCount(constraints.maxWidth);
        return RefreshIndicator(
          onRefresh: () async {
            await context.read<TenantCubit>().loadTenants();
          },
          child: columns == 1
              ? _buildList(context, displayTenants, isMutating)
              : _buildGrid(context, displayTenants, isMutating, columns),
        );
      },
    );
  }

  Widget _buildList(
      BuildContext context, List<TenantEntity> tenants, bool isMutating) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: tenants.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final tenant = tenants[index];
        final resolved = _resolveBed(context, tenant.bedId);
        return TenantCard(
          tenant: tenant,
          roomLabel: resolved.roomName,
          bedLabel: resolved.bedName,
          actionsEnabled: !isMutating,
          onEdit: () => _navigateToEditTenant(context, tenant),
          onDelete: () => _confirmDelete(context, tenant),
        );
      },
    );
  }

  Widget _buildGrid(BuildContext context, List<TenantEntity> tenants,
      bool isMutating, int columns) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.2,
      ),
      itemCount: tenants.length,
      itemBuilder: (context, index) {
        final tenant = tenants[index];
        final resolved = _resolveBed(context, tenant.bedId);
        return TenantCard(
          tenant: tenant,
          roomLabel: resolved.roomName,
          bedLabel: resolved.bedName,
          actionsEnabled: !isMutating,
          onEdit: () => _navigateToEditTenant(context, tenant),
          onDelete: () => _confirmDelete(context, tenant),
        );
      },
    );
  }
}

class _ResolvedBed {
  final String roomName;
  final String bedName;
  const _ResolvedBed(this.roomName, this.bedName);
}
