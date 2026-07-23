// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_empty_state.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../../domain/entities/checkout_settlement_entity.dart';
import '../../cubit/checkout/checkout_cubit.dart';
import '../../cubit/checkout/checkout_state.dart';

class CheckoutListPage extends StatefulWidget {
  const CheckoutListPage({super.key});
  @override
  State<CheckoutListPage> createState() => _CheckoutListPageState();
}

class _CheckoutListPageState extends State<CheckoutListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CheckoutCubit>().loadAllCheckoutSettlements();
    });
  }

  String _date(DateTime? value) => value == null
      ? 'Not set'
      : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  @override
  Widget build(BuildContext context) =>
      BlocListener<CheckoutCubit, CheckoutState>(
          listener: (context, state) {
            if (state is CheckoutError)
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error));
          },
          child: Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(title: const Text('Checkout Settlements')),
              floatingActionButton: FloatingActionButton.extended(
                  onPressed: () => context.pushNamed(AppRoutes.addCheckoutName),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Checkout')),
              body: BlocBuilder<CheckoutCubit, CheckoutState>(
                  builder: (context, state) {
                if (state is CheckoutInitial || state is CheckoutLoading)
                  return const Center(child: AppLoadingIndicator());
                if (state is CheckoutEmpty)
                  return const AppEmptyState(
                      icon: Icons.exit_to_app_outlined,
                      title: 'No checkout settlements found');
                if (state is CheckoutLoaded)
                  return RefreshIndicator(
                      onRefresh: () => context
                          .read<CheckoutCubit>()
                          .loadAllCheckoutSettlements(),
                      child: LayoutBuilder(builder: (context, constraints) {
                        final settlements = state.settlements;
                        if (constraints.maxWidth < 800)
                          return ListView.separated(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              itemCount: settlements.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: AppSpacing.sm),
                              itemBuilder: (context, index) => _CheckoutCard(
                                  settlement: settlements[index], date: _date));
                        return GridView.builder(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: AppSpacing.md,
                                    mainAxisSpacing: AppSpacing.md,
                                    childAspectRatio: 2.6),
                            itemCount: settlements.length,
                            itemBuilder: (context, index) => _CheckoutCard(
                                settlement: settlements[index], date: _date));
                      }));
                return const SizedBox.shrink();
              })));
}

class _CheckoutCard extends StatelessWidget {
  final CheckoutSettlementEntity settlement;
  final String Function(DateTime?) date;
  const _CheckoutCard({required this.settlement, required this.date});
  @override
  Widget build(BuildContext context) => Card(
      child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.pushNamed(AppRoutes.checkoutDetailsName,
              pathParameters: {'checkoutId': settlement.id!.toString()},
              extra: settlement),
          child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text('Stay ID: ${settlement.stayId}',
                              style: Theme.of(context).textTheme.titleMedium)),
                      Chip(label: Text(settlement.status))
                    ]),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Checkout: ${date(settlement.settlementDate)}'),
                    Text(
                        'Total charges: ${settlement.finalAmount.toStringAsFixed(2)}'),
                    Text(
                        'Total refund: ${settlement.refundAmount.toStringAsFixed(2)}')
                  ]))));
}
