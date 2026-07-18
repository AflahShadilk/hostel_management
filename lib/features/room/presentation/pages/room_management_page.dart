import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../hostel/presentation/cubit/hostel_cubit.dart';
import '../../../hostel/presentation/cubit/hostel_state.dart';
import '../../../hostel/presentation/cubit/hostel_status.dart';
import '../../domain/entities/room_entity.dart';
import '../cubit/room_cubit.dart';
import '../cubit/room_state.dart';
import '../cubit/room_operation_status.dart';
import '../widgets/room_card.dart';

class RoomManagementPage extends StatefulWidget {
  const RoomManagementPage({super.key});

  @override
  State<RoomManagementPage> createState() => _RoomManagementPageState();
}

class _RoomManagementPageState extends State<RoomManagementPage> {
  // Track whether we've triggered initial load to avoid repeated DB queries.
  bool _loadTriggered = false;

  @override
  void initState() {
    super.initState();
    // Defer the load to post-frame so HostelCubit state is settled.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_loadTriggered) {
        _loadTriggered = true;
        _triggerLoad();
      }
    });
  }

  void _triggerLoad() {
    final hostelId = context.read<HostelCubit>().state.hostel?.id;
    if (hostelId != null && hostelId > 0) {
      context.read<RoomCubit>().loadRooms(hostelId);
    } else {
      // Hostel not resolved yet — rely on BlocListener to catch configured state.
    }
  }

  int? get _hostelId => context.read<HostelCubit>().state.hostel?.id;

  void _navigateToAddRoom(BuildContext context) {
    context.pushNamed(AppRoutes.addRoomName).then((changed) {
      if (changed == true && mounted) _triggerLoad();
    });
  }

  void _navigateToEditRoom(BuildContext context, RoomEntity room) {
    context.pushNamed(
      AppRoutes.editRoomName,
      pathParameters: {'roomId': room.id!.toString()},
      extra: room,
    ).then((changed) {
      if (changed == true && mounted) _triggerLoad();
    });
  }

  Future<void> _navigateToManageBeds(
      BuildContext context, RoomEntity room) async {
    final changed = await context.pushNamed<bool>(
      AppRoutes.bedManagementName,
      pathParameters: {'roomId': room.id!.toString()},
      extra: room,
    );

    if (changed == true && mounted) {
      _triggerLoad();
    }
  }

  Future<void> _confirmDelete(BuildContext context, RoomEntity room) async {
    final roomCubit = context.read<RoomCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Room?'),
        content: Text(
          'Deleting Room ${room.roomNumber} will also remove its bed records. '
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
    if (confirmed == true) {
      roomCubit.deleteRoom(room);
    }
  }

  int _columnCount(double width) {
    if (width >= 900) return 3;
    if (width >= 600) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    // Listen to HostelCubit so we can trigger room load once hostel is resolved.
    return BlocListener<HostelCubit, HostelState>(
      listenWhen: (prev, curr) =>
          prev.status != curr.status && curr.status == HostelStatus.configured,
      listener: (context, hostelState) {
        final hostelId = hostelState.hostel?.id;
        if (hostelId != null && hostelId > 0 && !_loadTriggered) {
          _loadTriggered = true;
          context.read<RoomCubit>().loadRooms(hostelId);
        }
      },
      child: BlocConsumer<RoomCubit, RoomState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          if (state.status == RoomOperationStatus.created) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Room added successfully.')),
            );
          } else if (state.status == RoomOperationStatus.deleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Room deleted successfully.')),
            );
          } else if (state.status == RoomOperationStatus.failure &&
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
              title: const Text('Rooms'),
              backgroundColor: AppColors.surface,
              elevation: 0,
              scrolledUnderElevation: 1,
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _navigateToAddRoom(context),
              tooltip: 'Add Room',
              child: const Icon(Icons.add),
            ),
            body: _buildBody(context, state),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, RoomState state) {
    // Hostel not configured — show fallback.
    final hostelStatus = context.read<HostelCubit>().state.status;
    if (hostelStatus != HostelStatus.configured) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.business_outlined,
                  size: 48, color: AppColors.textSecondary),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Unable to load hostel information.',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Initial loading with no existing data.
    if (state.status == RoomOperationStatus.loading && state.rooms.isEmpty) {
      return const Center(child: AppLoadingIndicator());
    }

    // Initial failure with no existing data.
    if (state.status == RoomOperationStatus.failure && state.rooms.isEmpty) {
      return AppEmptyState(
        icon: Icons.error_outline,
        title: 'Unable to load rooms',
        message: state.errorMessage ?? 'Something went wrong.',
        action: AppButton(
          label: 'Retry',
          onPressed: () {
            final hostelId = _hostelId;
            if (hostelId != null) {
              context.read<RoomCubit>().loadRooms(hostelId);
            }
          },
        ),
      );
    }

    // Empty state.
    if (state.rooms.isEmpty) {
      return AppEmptyState(
        icon: Icons.meeting_room_outlined,
        title: 'No rooms added yet',
        message: 'Add your first room to start managing beds and occupancy.',
        action: AppButton(
          label: 'Add Room',
          icon: Icons.add,
          onPressed: () => _navigateToAddRoom(context),
        ),
      );
    }

    // Room list / grid.
    final isMutating = state.status == RoomOperationStatus.creating ||
        state.status == RoomOperationStatus.updating ||
        state.status == RoomOperationStatus.deleting;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnCount(constraints.maxWidth);
        return RefreshIndicator(
          onRefresh: () async {
            final hostelId = _hostelId;
            if (hostelId != null) {
              context.read<RoomCubit>().loadRooms(hostelId);
            }
          },
          child: columns == 1
              ? _buildList(context, state.rooms, isMutating)
              : _buildGrid(context, state.rooms, isMutating, columns),
        );
      },
    );
  }

  Widget _buildList(
      BuildContext context, List<RoomEntity> rooms, bool isMutating) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: rooms.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final room = rooms[index];
        return RoomCard(
          room: room,
          actionsEnabled: !isMutating,
          onManageBeds: () => _navigateToManageBeds(context, room),
          onEdit: () => _navigateToEditRoom(context, room),
          onDelete: () => _confirmDelete(context, room),
        );
      },
    );
  }

  Widget _buildGrid(BuildContext context, List<RoomEntity> rooms,
      bool isMutating, int columns) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        // childAspectRatio chosen to give cards enough height without overflow.
        childAspectRatio: 1.1,
      ),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        return RoomCard(
          room: room,
          actionsEnabled: !isMutating,
          onManageBeds: () => _navigateToManageBeds(context, room),
          onEdit: () => _navigateToEditRoom(context, room),
          onDelete: () => _confirmDelete(context, room),
        );
      },
    );
  }
}
