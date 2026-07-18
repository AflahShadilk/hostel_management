import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../room/domain/entities/bed_entity.dart';
import '../../../room/domain/entities/bed_status.dart';
import '../../../room/domain/entities/room_entity.dart';
import '../../../room/domain/repositories/bed_repository.dart';
import '../../../room/domain/repositories/room_repository.dart';

/// Encapsulates room + vacant beds for display purposes.
class _RoomWithBeds {
  final RoomEntity room;
  final List<BedEntity> beds;
  const _RoomWithBeds(this.room, this.beds);
}

/// Loads all rooms for [hostelId] and their vacant beds, then groups them for
/// selection. Uses [FutureBuilder] internally — no extra Cubit needed.
///
/// Calls [onBedSelected] when the user picks a bed. [selectedBed] reflects
/// the current selection so the widget can render the highlighted state.
class BedSelectionWidget extends StatefulWidget {
  final int hostelId;
  final BedEntity? selectedBed;
  final ValueChanged<BedEntity?> onBedSelected;

  const BedSelectionWidget({
    super.key,
    required this.hostelId,
    required this.selectedBed,
    required this.onBedSelected,
  });

  @override
  State<BedSelectionWidget> createState() => _BedSelectionWidgetState();
}

class _BedSelectionWidgetState extends State<BedSelectionWidget> {
  late Future<List<_RoomWithBeds>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadAvailableBeds();
  }

  Future<List<_RoomWithBeds>> _loadAvailableBeds() async {
    final roomRepo = getIt<RoomRepository>();
    final bedRepo = getIt<BedRepository>();

    final rooms = await roomRepo.getRoomsByHostelId(widget.hostelId);
    final result = <_RoomWithBeds>[];

    for (final room in rooms) {
      if (room.id == null) continue;
      final beds = await bedRepo.getVacantBedsByRoomId(room.id!);
      // getVacantBedsByRoomId only returns BedStatus.vacant — safe to include all.
      final activeBeds = beds.where((b) => b.status == BedStatus.vacant).toList();
      if (activeBeds.isNotEmpty) {
        result.add(_RoomWithBeds(room, activeBeds));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_RoomWithBeds>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              'Unable to load available beds.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.error),
            ),
          );
        }

        final groups = snapshot.data ?? [];

        if (groups.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'No vacant beds available. Add rooms and beds first.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final group in groups) ...[
                // Room header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    border: Border(
                      bottom: BorderSide(color: AppColors.border),
                    ),
                  ),
                  child: Text(
                    'Room ${group.room.roomNumber}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                  ),
                ),
                // Bed tiles
                for (final bed in group.beds)
                  _BedTile(
                    bed: bed,
                    room: group.room,
                    isSelected: widget.selectedBed?.id == bed.id,
                    onTap: () => widget.onBedSelected(
                      widget.selectedBed?.id == bed.id ? null : bed,
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _BedTile extends StatelessWidget {
  final BedEntity bed;
  final RoomEntity room;
  final bool isSelected;
  final VoidCallback onTap;

  const _BedTile({
    required this.bed,
    required this.room,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Bed ${bed.bedNumber}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:
                        isSelected ? AppColors.primary : AppColors.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Vacant',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
