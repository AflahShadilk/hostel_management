import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/rent_record_entity.dart';
import '../../../../communication/domain/repositories/communication_repository.dart';
import '../../cubit/rent_record/rent_record_cubit.dart';
import '../../cubit/rent_record/rent_record_state.dart';
import '../../cubit/ui/deleting_cubit.dart';

class RentRecordDetailsPage extends StatefulWidget {
  final RentRecordEntity? record;
  const RentRecordDetailsPage({super.key, required this.record});

  @override
  State<RentRecordDetailsPage> createState() => _RentRecordDetailsPageState();
}

class _RentRecordDetailsPageState extends State<RentRecordDetailsPage> {
  String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  Future<void> _delete(BuildContext context, RentRecordEntity record) async {
    final deletingCubit = context.read<DeletingCubit>();
    final mainCubit = context.read<RentRecordCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Rent Record?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true && record.id != null) {
      deletingCubit.start();
      mainCubit.deleteRentRecord(record.id!);
    }
  }

  Future<void> _sendDueReminder(RentRecordEntity record) async {
    final result = await getIt<CommunicationRepository>().shareText(
      'Rent reminder: ${record.formattedPeriod} rent for stay ${record.stayId} is due. '
      'Outstanding amount: ${(record.amountDue - record.amountPaid).toStringAsFixed(2)}.',
    );
    if (!mounted || result.isSuccess) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(result.message ?? 'Unable to share rent reminder.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    if (record == null) {
      return const Scaffold(
        body: Center(child: Text('Rent record data not found.')),
      );
    }
    final balance = record.amountDue - record.amountPaid;
    return BlocProvider<DeletingCubit>(
      create: (_) => DeletingCubit(),
      child: Builder(builder: (context) {
        return BlocListener<RentRecordCubit, RentRecordState>(
          listener: (context, state) {
            if (state is RentRecordError) {
              context.read<DeletingCubit>().stop();
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.message)));
            } else if (context.read<DeletingCubit>().state &&
                (state is RentRecordLoaded || state is RentRecordEmpty)) {
              context.pop(true);
            }
          },
          child: Scaffold(
            appBar: AppBar(title: const Text('Rent Record Details'), actions: [
              IconButton(
                  icon: const Icon(Icons.send_outlined),
                  tooltip: 'Send Rent Due Reminder',
                  onPressed: () => _sendDueReminder(record)),
              IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit',
                  onPressed: () => context.pushNamed(
                      AppRoutes.editRentRecordName,
                      pathParameters: {'rentRecordId': record.id!.toString()},
                      extra: record)),
              BlocBuilder<DeletingCubit, bool>(
                builder: (context, deleting) => IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete',
                  onPressed: deleting ? null : () => _delete(context, record),
                ),
              ),
            ]),
            body: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  Card(
                      child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Status: ${record.status}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                const Divider(),
                                _Row('Billing Period', record.formattedPeriod),
                                _Row('Rent Amount',
                                    record.amountDue.toStringAsFixed(2)),
                                _Row('Paid Amount',
                                    record.amountPaid.toStringAsFixed(2)),
                                _Row('Balance Amount',
                                    balance.toStringAsFixed(2)),
                                _Row('Due Date', _date(record.dueDate)),
                                _Row('Created Date', _date(record.createdAt)),
                                _Row('Updated Date', _date(record.updatedAt)),
                              ]))),
                ]),
          ),
        );
      }),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 150,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ]),
      );
}
