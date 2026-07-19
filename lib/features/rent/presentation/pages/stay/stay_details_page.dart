import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/stay_entity.dart';
import '../../cubit/stay/stay_cubit.dart';
import '../../cubit/stay/stay_state.dart';

class StayDetailsPage extends StatefulWidget {
  final StayEntity? stay;
  const StayDetailsPage({super.key, required this.stay});

  @override
  State<StayDetailsPage> createState() => _StayDetailsPageState();
}

class _StayDetailsPageState extends State<StayDetailsPage> {
  bool _deleting = false;

  String _date(DateTime? value) {
    if (value == null) return 'Not set';
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  Future<void> _confirmDelete(StayEntity stay) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Stay?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && stay.id != null && mounted) {
      setState(() => _deleting = true);
      context.read<StayCubit>().deleteStay(stay.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stay = widget.stay;
    if (stay == null) {
      return const Scaffold(body: Center(child: Text('Stay data not found.')));
    }
    return BlocListener<StayCubit, StayState>(
      listener: (context, state) {
        if (state is StayError) {
          setState(() => _deleting = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        } else if (_deleting && (state is StayLoaded || state is StayEmpty)) {
          context.pop(true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Stay Details'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: () => context.pushNamed(
                AppRoutes.editStayName,
                pathParameters: {'stayId': stay.id!.toString()},
                extra: stay,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: _deleting ? null : () => _confirmDelete(stay),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status: ${stay.status}', style: Theme.of(context).textTheme.titleMedium),
                    const Divider(),
                    _DetailRow('Stay ID', '${stay.id ?? 'Not assigned'}'),
                    _DetailRow('Tenant ID', '${stay.tenantId}'),
                    _DetailRow('Room ID', '${stay.roomId}'),
                    _DetailRow('Bed ID', '${stay.bedId}'),
                    _DetailRow('Check-in date', _date(stay.checkInDate)),
                    _DetailRow('Check-out date', _date(stay.checkOutDate)),
                    _DetailRow('Expected checkout date', _date(stay.expectedCheckoutDate)),
                    _DetailRow('Monthly rent snapshot', stay.monthlyRentSnapshot.toStringAsFixed(2)),
                    _DetailRow('Daily rate', stay.dailyRate.toStringAsFixed(2)),
                    _DetailRow('Created at', _date(stay.createdAt)),
                    _DetailRow('Updated at', _date(stay.updatedAt)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 170, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
