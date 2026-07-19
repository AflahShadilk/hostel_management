import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../room/domain/entities/bed_entity.dart';
import '../cubit/bed_selection_cubit.dart';
import '../cubit/bed_selection_state.dart';

/// Displays all vacant beds grouped by room for selection.
///
/// Architecture: uses [BedSelectionCubit] to load data following the
/// Presentation → Cubit → Repository → Datasource flow.
/// No FutureBuilder, no direct repository access in the widget.
class BedSelectionWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<BedSelectionCubit>()..loadAvailableBeds(hostelId),
      child: BlocBuilder<BedSelectionCubit, BedSelectionState>(
        builder: (context, state) {
          if (state is BedSelectionLoading || state is BedSelectionInitial) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (state is BedSelectionError) {
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

          if (state is BedSelectionLoaded) {
            final groups = state.roomWithBeds;

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
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                      ),
                    ),
                    // Bed tiles
                    for (final bed in group.beds)
                      _BedTile(
                        bed: bed,
                        roomNumber: group.room.roomNumber,
                        isSelected: selectedBed?.id == bed.id,
                        onTap: () => onBedSelected(
                          selectedBed?.id == bed.id ? null : bed,
                        ),
                      ),
                  ],
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _BedTile extends StatelessWidget {
  final BedEntity bed;
  final String roomNumber;
  final bool isSelected;
  final VoidCallback onTap;

  const _BedTile({
    required this.bed,
    required this.roomNumber,
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
            bottom:
                BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
