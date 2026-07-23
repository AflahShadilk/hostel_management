// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_empty_state.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../../../../core/widgets/app_safe_area_fab.dart';
import '../../../domain/entities/damage_charge_entity.dart';
import '../../cubit/damage_charge/damage_charge_cubit.dart';
import '../../cubit/damage_charge/damage_charge_state.dart';

class DamageChargeListPage extends StatefulWidget {
  const DamageChargeListPage({super.key});
  @override
  State<DamageChargeListPage> createState() => _DamageChargeListPageState();
}

class _DamageChargeListPageState extends State<DamageChargeListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DamageChargeCubit>().loadAllDamageCharges();
    });
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<DamageChargeCubit, DamageChargeState>(
          listener: (context, state) {
            if (state is DamageChargeError)
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error));
          },
          child: Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(title: const Text('Damage Charges')),
              floatingActionButton: AppSafeAreaFab(
                  child: FloatingActionButton.extended(
                      onPressed: () =>
                          context.pushNamed(AppRoutes.addDamageChargeName),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Damage Charge'))),
              body: BlocBuilder<DamageChargeCubit, DamageChargeState>(
                  builder: (context, state) {
                if (state is DamageChargeInitial ||
                    state is DamageChargeLoading)
                  return const Center(child: AppLoadingIndicator());
                if (state is DamageChargeEmpty)
                  return const AppEmptyState(
                      icon: Icons.warning_amber_outlined,
                      title: 'No damage charges found');
                if (state is DamageChargeLoaded)
                  return RefreshIndicator(
                      onRefresh: () => context
                          .read<DamageChargeCubit>()
                          .loadAllDamageCharges(),
                      child: LayoutBuilder(builder: (context, constraints) {
                        final charges = state.damageCharges;
                        if (constraints.maxWidth < 800)
                          return ListView.separated(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              itemCount: charges.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: AppSpacing.sm),
                              itemBuilder: (context, index) =>
                                  _ChargeCard(charge: charges[index]));
                        return GridView.builder(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: AppSpacing.md,
                                    mainAxisSpacing: AppSpacing.md,
                                    childAspectRatio: 2.8),
                            itemCount: charges.length,
                            itemBuilder: (context, index) =>
                                _ChargeCard(charge: charges[index]));
                      }));
                return const SizedBox.shrink();
              })));
}

class _ChargeCard extends StatelessWidget {
  final DamageChargeEntity charge;
  const _ChargeCard({required this.charge});
  @override
  Widget build(BuildContext context) => Card(
      child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.pushNamed(AppRoutes.damageChargeDetailsName,
              pathParameters: {'damageChargeId': charge.id!.toString()},
              extra: charge),
          child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text('Stay ID: ${charge.stayId}',
                              style: Theme.of(context).textTheme.titleMedium)),
                      Chip(label: Text(charge.status))
                    ]),
                    const SizedBox(height: AppSpacing.sm),
                    Text(charge.description),
                    Text('Amount: ${charge.amount.toStringAsFixed(2)}')
                  ]))));
}
