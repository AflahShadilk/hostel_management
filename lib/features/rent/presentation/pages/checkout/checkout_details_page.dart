import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/checkout_settlement_entity.dart';
import '../../cubit/checkout/checkout_cubit.dart';
import '../../cubit/checkout/checkout_state.dart';
import '../../cubit/ui/deleting_cubit.dart';

class CheckoutDetailsPage extends StatefulWidget {
  final CheckoutSettlementEntity? settlement;
  const CheckoutDetailsPage({super.key, required this.settlement});
  @override
  State<CheckoutDetailsPage> createState() => _CheckoutDetailsPageState();
}

class _CheckoutDetailsPageState extends State<CheckoutDetailsPage> {
  String _date(DateTime? value) => value == null
      ? 'Not set'
      : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  Future<void> _delete(BuildContext context, CheckoutSettlementEntity settlement) async {
    final deletingCubit = context.read<DeletingCubit>();
    final mainCubit = context.read<CheckoutCubit>();
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
                title: const Text('Delete Checkout Settlement?'),
                content: const Text('This action cannot be undone.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.error),
                      child: const Text('Delete'))
                ]));
    if (confirmed == true && settlement.id != null) {
      deletingCubit.start();
      mainCubit.deleteCheckoutSettlement(settlement.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settlement = widget.settlement;
    if (settlement == null) {
      return const Scaffold(
          body: Center(child: Text('Checkout settlement data not found.')));
    }
    return BlocProvider<DeletingCubit>(
      create: (_) => DeletingCubit(),
      child: Builder(builder: (context) {
        return BlocListener<CheckoutCubit, CheckoutState>(
            listener: (context, state) {
              if (state is CheckoutError) {
                context.read<DeletingCubit>().stop();
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(state.message)));
              } else if (context.read<DeletingCubit>().state &&
                  (state is CheckoutLoaded || state is CheckoutEmpty)) {
                context.pop(true);
              }
            },
            child: Scaffold(
                appBar: AppBar(title: const Text('Checkout Details'), actions: [
                  IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit',
                      onPressed: () => context.pushNamed(
                          AppRoutes.editCheckoutName,
                          pathParameters: {
                            'checkoutId': settlement.id!.toString()
                          },
                          extra: settlement)),
                  BlocBuilder<DeletingCubit, bool>(
                    builder: (context, deleting) => IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Delete',
                        onPressed: deleting
                            ? null
                            : () => _delete(context, settlement)),
                  )
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
                                    Text('Status: ${settlement.status}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium),
                                    const Divider(),
                                    _Row('Stay ID', '${settlement.stayId}'),
                                    _Row('Checkout Date',
                                        _date(settlement.settlementDate)),
                                    _Row('Total Charges',
                                        settlement.finalAmount.toStringAsFixed(2)),
                                    _Row('Total Refund',
                                        settlement.refundAmount.toStringAsFixed(2)),
                                    _Row('Created Date',
                                        _date(settlement.createdAt)),
                                    _Row('Updated Date',
                                        _date(settlement.updatedAt))
                                  ])))
                    ])));
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
        Expanded(child: Text(value))
      ]));
}
