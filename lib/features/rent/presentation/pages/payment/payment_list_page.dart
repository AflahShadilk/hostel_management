import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_empty_state.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../../domain/entities/payment_entity.dart';
import '../../cubit/payment/payment_cubit.dart';
import '../../cubit/payment/payment_state.dart';

class PaymentListPage extends StatefulWidget {
  const PaymentListPage({super.key});

  @override
  State<PaymentListPage> createState() => _PaymentListPageState();
}

class _PaymentListPageState extends State<PaymentListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PaymentCubit>().loadAllPayments();
    });
  }

  String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  @override
  Widget build(BuildContext context) => BlocListener<PaymentCubit, PaymentState>(
    listener: (context, state) {
      if (state is PaymentError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
        );
      }
    },
    child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Payments')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(AppRoutes.addPaymentName),
        icon: const Icon(Icons.add),
        label: const Text('Add Payment'),
      ),
      body: BlocBuilder<PaymentCubit, PaymentState>(
        builder: (context, state) {
          if (state is PaymentInitial || state is PaymentLoading) { return const Center(child: AppLoadingIndicator()); }
          if (state is PaymentEmpty) { return const AppEmptyState(icon: Icons.payments_outlined, title: 'No payments found'); }
          if (state is PaymentLoaded) { return RefreshIndicator(
            onRefresh: () => context.read<PaymentCubit>().loadAllPayments(),
            child: LayoutBuilder(builder: (context, constraints) {
              final payments = state.payments;
              if (constraints.maxWidth < 800) { return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md), itemCount: payments.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) => _PaymentCard(payment: payments[index], date: _date),
              ); }
              return GridView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: AppSpacing.md, mainAxisSpacing: AppSpacing.md, childAspectRatio: 3.5),
                itemCount: payments.length,
                itemBuilder: (context, index) => _PaymentCard(payment: payments[index], date: _date),
              );
            }),
          ); }
          return const SizedBox.shrink();
        },
      ),
    ),
  );
}

class _PaymentCard extends StatelessWidget {
  final PaymentEntity payment;
  final String Function(DateTime) date;
  const _PaymentCard({required this.payment, required this.date});

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.pushNamed(AppRoutes.paymentDetailsName, pathParameters: {'paymentId': payment.id!.toString()}, extra: payment),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text(date(payment.paymentDate), style: Theme.of(context).textTheme.titleMedium)), Chip(label: Text(payment.status))]),
          const SizedBox(height: AppSpacing.sm),
          Text('Amount: ${payment.amount.toStringAsFixed(2)}'),
          Text('Method: ${payment.paymentMethod}'),
          Text('Rent record ID: ${payment.rentRecordId}'),
        ]),
      ),
    ),
  );
}
