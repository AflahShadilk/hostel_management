import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/receipt_entity.dart';
import '../../cubit/receipt/receipt_cubit.dart';
import '../../cubit/receipt/receipt_state.dart';
import '../../cubit/ui/deleting_cubit.dart';

class ReceiptDetailsPage extends StatefulWidget {
  final ReceiptEntity? receipt;
  const ReceiptDetailsPage({super.key, required this.receipt});
  @override
  State<ReceiptDetailsPage> createState() => _ReceiptDetailsPageState();
}

class _ReceiptDetailsPageState extends State<ReceiptDetailsPage> {
  String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}/' '${value.month.toString().padLeft(2, '0')}/${value.year}';
  Future<void> _delete(BuildContext context, ReceiptEntity receipt) async {
    final deletingCubit = context.read<DeletingCubit>();
    final mainCubit = context.read<ReceiptCubit>();
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Delete Receipt?'), content: const Text('This action cannot be undone.'), actions: [
      TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
      TextButton(onPressed: () => Navigator.pop(dialogContext, true), style: TextButton.styleFrom(foregroundColor: AppColors.error), child: const Text('Delete')),
    ]));
    if (confirmed == true && receipt.id != null) {
      deletingCubit.start();
      mainCubit.deleteReceipt(receipt.id!);
    }
  }
  @override
  Widget build(BuildContext context) {
    final receipt = widget.receipt;
    if (receipt == null) return const Scaffold(body: Center(child: Text('Receipt data not found.')));
    return BlocProvider<DeletingCubit>(
      create: (_) => DeletingCubit(),
      child: Builder(builder: (context) {
        return BlocListener<ReceiptCubit, ReceiptState>(listener: (context, state) {
          if (state is ReceiptError) {
            context.read<DeletingCubit>().stop();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          } else if (context.read<DeletingCubit>().state &&
              (state is ReceiptLoaded || state is ReceiptEmpty)) {
            context.pop(true);
          }
        }, child: Scaffold(
          appBar: AppBar(title: const Text('Receipt Details'), actions: [
            IconButton(icon: const Icon(Icons.edit_outlined), tooltip: 'Edit', onPressed: () => context.pushNamed(AppRoutes.editReceiptName, pathParameters: {'receiptId': receipt.id!.toString()}, extra: receipt)),
            BlocBuilder<DeletingCubit, bool>(
              builder: (context, deleting) => IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete',
                onPressed: deleting ? null : () => _delete(context, receipt),
              ),
            ),
          ]),
          body: ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [Card(child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(receipt.receiptNumber, style: Theme.of(context).textTheme.titleMedium), const Divider(),
            _Row('Receipt Number', receipt.receiptNumber), _Row('Payment ID', '${receipt.paymentId}'), _Row('Payment Amount', receipt.paymentAmountSnapshot.toStringAsFixed(2)), _Row('Payment Method', receipt.paymentMethodSnapshot), _Row('Issued Date', _date(receipt.issuedAt)), _Row('Created Date', _date(receipt.createdAt)), _Row('Updated Date', _date(receipt.updatedAt)),
          ])))],),
        ));
      }),
    );
  }
}
class _Row extends StatelessWidget { final String label; final String value; const _Row(this.label, this.value); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 150, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))), Expanded(child: Text(value))])); }
