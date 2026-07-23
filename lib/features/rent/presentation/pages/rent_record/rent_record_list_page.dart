import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_empty_state.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../../../../core/widgets/app_dashboard_ui.dart';
import '../../../domain/entities/rent_record_entity.dart';
import '../../cubit/rent_record/rent_record_cubit.dart';
import '../../cubit/rent_record/rent_record_state.dart';

class RentRecordListPage extends StatefulWidget {
  const RentRecordListPage({super.key});

  @override
  State<RentRecordListPage> createState() => _RentRecordListPageState();
}

class _RentRecordListPageState extends State<RentRecordListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<RentRecordCubit>().loadAllRentRecords();
    });
  }

  String _date(DateTime date) => '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) {
    return BlocListener<RentRecordCubit, RentRecordState>(
      listener: (context, state) {
        if (state is RentRecordError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message), backgroundColor: AppColors.error),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Rent Records')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.pushNamed(AppRoutes.addRentRecordName),
          icon: const Icon(Icons.add),
          label: const Text('Add Rent Record'),
        ),
        body: BlocBuilder<RentRecordCubit, RentRecordState>(
          builder: (context, state) {
            if (state is RentRecordInitial || state is RentRecordLoading) {
              return const Center(child: AppLoadingIndicator());
            }
            if (state is RentRecordEmpty) {
              return const AppEmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No rent records found',
              );
            }
            if (state is RentRecordLoaded) {
              return RefreshIndicator(
                onRefresh: () =>
                    context.read<RentRecordCubit>().loadAllRentRecords(),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final records = state.records;
                    if (constraints.maxWidth < 800) {
                      return ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: records.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) => _RentRecordCard(
                            record: records[index], date: _date),
                      );
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                        childAspectRatio: 2.1,
                      ),
                      itemCount: records.length,
                      itemBuilder: (context, index) =>
                          _RentRecordCard(record: records[index], date: _date),
                    );
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _RentRecordCard extends StatelessWidget {
  final RentRecordEntity record;
  final String Function(DateTime) date;
  const _RentRecordCard({required this.record, required this.date});

  @override
  Widget build(BuildContext context) {
    final balance = record.amountDue - record.amountPaid;
    return AppDashboardCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.pushNamed(
          AppRoutes.rentRecordDetailsName,
          pathParameters: {'rentRecordId': record.id!.toString()},
          extra: record,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                    child: Text(record.formattedPeriod,
                        style: Theme.of(context).textTheme.titleMedium)),
                Chip(label: Text(record.status)),
              ]),
              const SizedBox(height: AppSpacing.sm),
              Text('Due date: ${date(record.dueDate)}'),
              Text('Amount: ${record.amountDue.toStringAsFixed(2)}'),
              Text('Paid: ${record.amountPaid.toStringAsFixed(2)}'),
              Text('Balance: ${balance.toStringAsFixed(2)}'),
            ],
          ),
        ),
      ),
    );
  }
}
