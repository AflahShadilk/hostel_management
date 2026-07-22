import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_empty_state.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../../../../core/widgets/app_safe_area_fab.dart';
import '../../../domain/entities/receipt_entity.dart';
import '../../cubit/receipt/receipt_cubit.dart';
import '../../cubit/receipt/receipt_state.dart';

class ReceiptListPage extends StatefulWidget {
  const ReceiptListPage({super.key});
  @override
  State<ReceiptListPage> createState() => _ReceiptListPageState();
}

class _ReceiptListPageState extends State<ReceiptListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ReceiptCubit>().loadAllReceipts();
    });
  }

  String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  @override
  Widget build(BuildContext context) => BlocListener<ReceiptCubit, ReceiptState>(
    listener: (context, state) {
      if (state is ReceiptError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error));
      }
    },
    child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Receipts')),
      floatingActionButton: AppSafeAreaFab(child: FloatingActionButton.extended(onPressed: () => context.pushNamed(AppRoutes.addReceiptName), icon: const Icon(Icons.add), label: const Text('Add Receipt'))),
      body: BlocBuilder<ReceiptCubit, ReceiptState>(builder: (context, state) {
        if (state is ReceiptInitial || state is ReceiptLoading) { return const Center(child: AppLoadingIndicator()); }
        if (state is ReceiptEmpty) { return const AppEmptyState(icon: Icons.receipt_long_outlined, title: 'No receipts found'); }
        if (state is ReceiptLoaded) { return RefreshIndicator(onRefresh: () => context.read<ReceiptCubit>().loadAllReceipts(), child: LayoutBuilder(builder: (context, constraints) {
          final receipts = state.receipts;
          if (constraints.maxWidth < 800) { return ListView.separated(padding: const EdgeInsets.all(AppSpacing.md), itemCount: receipts.length, separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm), itemBuilder: (context, index) => _ReceiptCard(receipt: receipts[index], date: _date)); }
          return GridView.builder(padding: const EdgeInsets.all(AppSpacing.md), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: AppSpacing.md, mainAxisSpacing: AppSpacing.md, childAspectRatio: 3.5), itemCount: receipts.length, itemBuilder: (context, index) => _ReceiptCard(receipt: receipts[index], date: _date));
        })); }
        return const SizedBox.shrink();
      }),
    ),
  );
}

class _ReceiptCard extends StatelessWidget {
  final ReceiptEntity receipt; final String Function(DateTime) date;
  const _ReceiptCard({required this.receipt, required this.date});
  @override
  Widget build(BuildContext context) => Card(child: InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () => context.pushNamed(AppRoutes.receiptDetailsName, pathParameters: {'receiptId': receipt.id!.toString()}, extra: receipt),
    child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(receipt.receiptNumber, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: AppSpacing.sm),
      Text('Payment ID: ${receipt.paymentId}'),
      Text('Amount: ${receipt.paymentAmountSnapshot.toStringAsFixed(2)}'),
      Text('Method: ${receipt.paymentMethodSnapshot}'),
      Text('Issued: ${date(receipt.issuedAt)}'),
    ])),
  ));
}
