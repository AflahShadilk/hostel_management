// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dashboard_ui.dart';
import '../../domain/entities/room_entity.dart';
import '../../domain/entities/bed_entity.dart';
import '../../domain/entities/bed_status.dart';
import '../cubit/bed_cubit.dart';
import '../cubit/bed_state.dart';
import '../cubit/bed_operation_status.dart';
import '../cubit/bed_filter.dart';
import '../cubit/bed_filter_cubit.dart';
import '../widgets/bed_card.dart';
import '../extensions/room_presentation_extensions.dart';
import '../cubit/room_cubit.dart';

class BedManagementPage extends StatefulWidget {
  final String roomIdStr;
  final RoomEntity? room;

  const BedManagementPage({
    super.key,
    required this.roomIdStr,
    this.room,
  });

  @override
  State<BedManagementPage> createState() => _BedManagementPageState();
}

class _BedManagementPageState extends State<BedManagementPage> {
  bool _loadTriggered = false;
  bool _bedChanged = false; // Track changes to return to RoomManagementPage
  RoomEntity? _resolvedRoom;

  @override
  void initState() {
    super.initState();
    _resolvedRoom = widget.room;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _resolveRoomAndLoadBeds();
      }
    });
  }

  void _resolveRoomAndLoadBeds() {
    if (_loadTriggered) return;

    final roomId = int.tryParse(widget.roomIdStr) ?? 0;
    if (roomId <= 0) return;

    if (_resolvedRoom == null) {
      // Attempt to resolve from RoomCubit state
      final roomState = context.read<RoomCubit>().state;
      try {
        _resolvedRoom = roomState.rooms.firstWhere((r) => r.id == roomId);
      } catch (_) {
        // Room not found, leave as null
      }
    }

    if (_resolvedRoom != null) {
      _loadTriggered = true;
      context.read<BedCubit>().loadBeds(roomId);
    }
  }

  void _onSetInactive(BuildContext context, BedEntity bed) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Set Bed Inactive?'),
        content: const Text(
          'This bed will be unavailable until it is reactivated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Set Inactive'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<BedCubit>().updateBedStatus(
            bed: bed,
            status: BedStatus.inactive,
          );
    }
  }

  void _onReactivate(BuildContext context, BedEntity bed) {
    context.read<BedCubit>().updateBedStatus(
          bed: bed,
          status: BedStatus.vacant,
        );
  }

  int _columnCount(double width) {
    if (width >= 1000) return 4;
    if (width >= 700) return 3;
    if (width >= 400) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BedFilterCubit(),
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, _) {
          // Will not fire because canPop: true allows GoRouter pop naturally,
          // but we manage our return via AppBar back button override below.
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              _resolvedRoom != null
                  ? 'Room ${_resolvedRoom!.roomNumber} — Beds'
                  : 'Beds',
            ),
            backgroundColor: AppColors.surface,
            elevation: 0,
            scrolledUnderElevation: 1,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (context.canPop()) {
                  context.pop(_bedChanged);
                }
              },
            ),
          ),
          body: _buildMainBody(context),
        ),
      ),
    );
  }

  Widget _buildMainBody(BuildContext context) {
    if (_resolvedRoom == null) {
      return const AppEmptyState(
        icon: Icons.error_outline,
        title: 'Room information unavailable',
        message: 'Return to Rooms and open this room again.',
      );
    }

    return BlocConsumer<BedCubit, BedState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == BedOperationStatus.updated) {
          _bedChanged = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bed status updated successfully.')),
          );
        } else if (state.status == BedOperationStatus.failure &&
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
        if (state.status == BedOperationStatus.loading && state.beds.isEmpty) {
          return const Center(child: AppLoadingIndicator());
        }

        if (state.status == BedOperationStatus.failure && state.beds.isEmpty) {
          return AppEmptyState(
            icon: Icons.error_outline,
            title: 'Unable to load beds',
            message: state.errorMessage ?? 'Something went wrong.',
            action: AppButton(
              label: 'Retry',
              onPressed: () {
                final roomId = int.tryParse(widget.roomIdStr) ?? 0;
                if (roomId > 0) {
                  context.read<BedCubit>().loadBeds(roomId);
                }
              },
            ),
          );
        }

        return Column(
          children: [
            _buildRoomSummary(context),
            _buildBedSummary(context, state.beds),
            _buildFilter(context),
            Expanded(
              child: _buildBedsContent(context, state),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRoomSummary(BuildContext context) {
    final room = _resolvedRoom!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      child: AppDashboardCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Room ${room.roomNumber}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${room.floor} · ${room.roomType.label} · ${room.numberOfBeds} Configured Beds',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Status: ${room.status.label}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBedSummary(BuildContext context, List<BedEntity> beds) {
    int total = beds.length;
    int vacant = 0;
    int occupied = 0;
    int inactive = 0;

    for (final b in beds) {
      if (b.status == BedStatus.vacant) {
        vacant++;
      } else if (b.status == BedStatus.occupied) {
        occupied++;
      } else if (b.status == BedStatus.inactive) {
        inactive++;
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: LayoutBuilder(builder: (context, constraints) {
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          alignment: WrapAlignment.center,
          children: [
            _SummaryCard(
                label: 'Total', count: total, color: AppColors.primary),
            _SummaryCard(
                label: 'Vacant', count: vacant, color: AppColors.success),
            _SummaryCard(
                label: 'Occupied', count: occupied, color: AppColors.error),
            _SummaryCard(
                label: 'Inactive',
                count: inactive,
                color: AppColors.textSecondary),
          ],
        );
      }),
    );
  }

  Widget _buildFilter(BuildContext context) {
    return BlocBuilder<BedFilterCubit, BedFilter>(
      builder: (context, selectedFilter) {
        return Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Wrap(
              spacing: AppSpacing.sm,
              children: BedFilter.values.map((filter) {
                final isSelected = filter == selectedFilter;
                return AppFilterChip(
                  label: filter.label,
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      context.read<BedFilterCubit>().selectFilter(filter);
                    }
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBedsContent(BuildContext context, BedState state) {
    if (state.beds.isEmpty) {
      return const AppEmptyState(
        icon: Icons.single_bed_outlined,
        title: 'No beds found',
        message: 'No bed records are available for this room.',
      );
    }

    return BlocBuilder<BedFilterCubit, BedFilter>(
      builder: (context, filter) {
        final filteredBeds = state.beds.where((b) {
          switch (filter) {
            case BedFilter.all:
              return true;
            case BedFilter.vacant:
              return b.status == BedStatus.vacant;
            case BedFilter.occupied:
              return b.status == BedStatus.occupied;
            case BedFilter.inactive:
              return b.status == BedStatus.inactive;
          }
        }).toList();

        if (filteredBeds.isEmpty) {
          final emptyMessage = switch (filter) {
            BedFilter.all => 'No beds have been added to this room yet.',
            BedFilter.vacant => 'No vacant beds found.',
            BedFilter.occupied => 'No occupied beds.',
            BedFilter.inactive => 'No inactive beds.',
          };
          return AppEmptyState(
            icon: Icons.single_bed_outlined,
            title: 'No beds to show',
            message: emptyMessage,
          );
        }

        final isMutating = state.status == BedOperationStatus.updating;

        return LayoutBuilder(builder: (context, constraints) {
          final columns = _columnCount(constraints.maxWidth);

          return RefreshIndicator(
            onRefresh: () async {
              final roomId = int.tryParse(widget.roomIdStr) ?? 0;
              if (roomId > 0) {
                await context.read<BedCubit>().loadBeds(roomId);
              }
            },
            child: columns == 1
                ? ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: filteredBeds.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final bed = filteredBeds[index];
                      return BedCard(
                        bed: bed,
                        actionsEnabled: !isMutating,
                        onSetInactive: () => _onSetInactive(context, bed),
                        onReactivate: () => _onReactivate(context, bed),
                      );
                    },
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                      childAspectRatio: 1.8,
                    ),
                    itemCount: filteredBeds.length,
                    itemBuilder: (context, index) {
                      final bed = filteredBeds[index];
                      return BedCard(
                        bed: bed,
                        actionsEnabled: !isMutating,
                        onSetInactive: () => _onSetInactive(context, bed),
                        onReactivate: () => _onReactivate(context, bed),
                      );
                    },
                  ),
          );
        });
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      child: AppDashboardCard(
        backgroundColor: color.withValues(alpha: 0.1),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.xs,
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
