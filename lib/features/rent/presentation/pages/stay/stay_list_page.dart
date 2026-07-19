import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_empty_state.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../../domain/entities/stay_entity.dart';
import '../../cubit/stay/stay_cubit.dart';
import '../../cubit/stay/stay_state.dart';

class StayListPage extends StatefulWidget {
  const StayListPage({super.key});

  @override
  State<StayListPage> createState() => _StayListPageState();
}

class _StayListPageState extends State<StayListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<StayCubit>().loadAllStays();
    });
  }

  String _date(DateTime? value) {
    if (value == null) return 'Not set';
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StayCubit, StayState>(
      listener: (context, state) {
        if (state is StayError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Stays')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.pushNamed(AppRoutes.addStayName),
          icon: const Icon(Icons.add),
          label: const Text('Add Stay'),
        ),
        body: BlocBuilder<StayCubit, StayState>(
          builder: (context, state) {
            if (state is StayLoading || state is StayInitial) {
              return const Center(child: AppLoadingIndicator());
            }
            if (state is StayEmpty) {
              return const AppEmptyState(
                icon: Icons.hotel_outlined,
                title: 'No stays found',
              );
            }
            if (state is StayLoaded) {
              return RefreshIndicator(
                onRefresh: () => context.read<StayCubit>().loadAllStays(),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 800 ? 2 : 1;
                    if (columns == 1) {
                      return ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: state.stays.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) => _StayCard(
                          stay: state.stays[index],
                          date: _date,
                        ),
                      );
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                        childAspectRatio: 2.2,
                      ),
                      itemCount: state.stays.length,
                      itemBuilder: (context, index) => _StayCard(
                        stay: state.stays[index],
                        date: _date,
                      ),
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

class _StayCard extends StatelessWidget {
  final StayEntity stay;
  final String Function(DateTime?) date;

  const _StayCard({required this.stay, required this.date});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.pushNamed(
          AppRoutes.stayDetailsName,
          pathParameters: {'stayId': stay.id!.toString()},
          extra: stay,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Tenant #${stay.tenantId}',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  Chip(label: Text(stay.status)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('Room ${stay.roomId} · Bed ${stay.bedId}'),
              Text('Check-in: ${date(stay.checkInDate)}'),
              Text('Expected checkout: ${date(stay.expectedCheckoutDate)}'),
              const SizedBox(height: AppSpacing.sm),
              Text('Monthly rent: ${stay.monthlyRentSnapshot.toStringAsFixed(2)}'),
            ],
          ),
        ),
      ),
    );
  }
}
