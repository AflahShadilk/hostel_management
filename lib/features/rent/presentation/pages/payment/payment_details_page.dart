import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/payment_entity.dart';
import '../../cubit/payment/payment_cubit.dart';
import '../../cubit/payment/payment_state.dart';
import '../../cubit/ui/deleting_cubit.dart';

class PaymentDetailsPage extends StatefulWidget {
  final PaymentEntity? payment;
  const PaymentDetailsPage({super.key, required this.payment});
  @override
  State<PaymentDetailsPage> createState() => _PaymentDetailsPageState();
}

class _PaymentDetailsPageState extends State<PaymentDetailsPage> {
  String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  Future<void> _delete(BuildContext context, PaymentEntity payment) async {
    final deletingCubit = context.read<DeletingCubit>();
    final mainCubit = context.read<PaymentCubit>();
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: const Text('Delete Payment?'),
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
            ));
    if (confirmed == true && payment.id != null) {
      deletingCubit.start();
      mainCubit.deletePayment(payment.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final payment = widget.payment;
    if (payment == null) return const Scaffold(body: Center(child: Text('Payment data not found.')));
    return BlocProvider<DeletingCubit>(
      create: (_) => DeletingCubit(),
      child: Builder(builder: (context) {
        return BlocListener<PaymentCubit, PaymentState>(
          listener: (context, state) {
            if (state is PaymentError) {
              context.read<DeletingCubit>().stop();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
            } else if (context.read<DeletingCubit>().state &&
                (state is PaymentLoaded || state is PaymentEmpty)) {
              context.pop(true);
            }
          },
          child: Scaffold(
            appBar: AppBar(title: const Text('Payment Details'), actions: [
              IconButton(icon: const Icon(Icons.edit_outlined), tooltip: 'Edit', onPressed: () => context.pushNamed(AppRoutes.editPaymentName, pathParameters: {'paymentId': payment.id!.toString()}, extra: payment)),
              BlocBuilder<DeletingCubit, bool>(
                builder: (context, deleting) => IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete',
                  onPressed: deleting ? null : () => _delete(context, payment),
                ),
              ),
            ]),
            body: ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [
              Card(child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Status: ${payment.status}', style: Theme.of(context).textTheme.titleMedium), const Divider(),
                _Row('Payment ID', '${payment.id ?? 'Not assigned'}'),
                _Row('Rent Record ID', '${payment.rentRecordId}'),
                _Row('Payment Date', _date(payment.paymentDate)),
                _Row('Amount', payment.amount.toStringAsFixed(2)),
                _Row('Payment Method', payment.paymentMethod),
                _Row('Created Date', _date(payment.createdAt)),
                _Row('Updated Date', _date(payment.updatedAt)),
              ]))),
            ]),
          ),
        );
      }),
    );
  }
}

class _Row extends StatelessWidget {
  final String label; final String value;
  const _Row(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 150, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))), Expanded(child: Text(value)),
    ]),
  );
}
