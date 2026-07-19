import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_empty_state.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../../domain/entities/deposit_entity.dart';
import '../../cubit/deposit/deposit_cubit.dart';
import '../../cubit/deposit/deposit_state.dart';

class DepositListPage extends StatefulWidget {
  const DepositListPage({super.key});
  @override State<DepositListPage> createState() => _DepositListPageState();
}
class _DepositListPageState extends State<DepositListPage> {
  @override void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) context.read<DepositCubit>().loadAllDeposits(); }); }
  String _date(DateTime? value) => value == null ? 'Not set' : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  @override Widget build(BuildContext context) => BlocListener<DepositCubit, DepositState>(
    listener: (context, state) { if (state is DepositError) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error)); } },
    child: Scaffold(backgroundColor: AppColors.background, appBar: AppBar(title: const Text('Deposits')), floatingActionButton: FloatingActionButton.extended(onPressed: () => context.pushNamed(AppRoutes.addDepositName), icon: const Icon(Icons.add), label: const Text('Add Deposit')),
      body: BlocBuilder<DepositCubit, DepositState>(builder: (context, state) {
        if (state is DepositInitial || state is DepositLoading) { return const Center(child: AppLoadingIndicator()); }
        if (state is DepositEmpty) { return const AppEmptyState(icon: Icons.account_balance_wallet_outlined, title: 'No deposits found'); }
        if (state is DepositLoaded) { return RefreshIndicator(onRefresh: () => context.read<DepositCubit>().loadAllDeposits(), child: LayoutBuilder(builder: (context, constraints) {
          final deposits = state.deposits;
          if (constraints.maxWidth < 800) { return ListView.separated(padding: const EdgeInsets.all(AppSpacing.md), itemCount: deposits.length, separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm), itemBuilder: (context, index) => _DepositCard(deposit: deposits[index], date: _date)); }
          return GridView.builder(padding: const EdgeInsets.all(AppSpacing.md), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: AppSpacing.md, mainAxisSpacing: AppSpacing.md, childAspectRatio: 2.5), itemCount: deposits.length, itemBuilder: (context, index) => _DepositCard(deposit: deposits[index], date: _date));
        })); }
        return const SizedBox.shrink();
      }),
    ),
  );
}
class _DepositCard extends StatelessWidget {
  final DepositEntity deposit; final String Function(DateTime?) date;
  const _DepositCard({required this.deposit, required this.date});
  @override Widget build(BuildContext context) => Card(child: InkWell(borderRadius: BorderRadius.circular(12), onTap: () => context.pushNamed(AppRoutes.depositDetailsName, pathParameters: {'depositId': deposit.id!.toString()}, extra: deposit), child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Expanded(child: Text('Stay ID: ${deposit.stayId}', style: Theme.of(context).textTheme.titleMedium)), Chip(label: Text(deposit.status))]), const SizedBox(height: AppSpacing.sm), Text('Deposit: ${deposit.amount.toStringAsFixed(2)}'), Text('Refunded: ${deposit.refundedAmount.toStringAsFixed(2)}'), Text('Received: ${date(deposit.receivedDate)}'),
  ]))));
}
