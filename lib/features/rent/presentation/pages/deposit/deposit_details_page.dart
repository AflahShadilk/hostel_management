import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/deposit_entity.dart';
import '../../cubit/deposit/deposit_cubit.dart';
import '../../cubit/deposit/deposit_state.dart';

class DepositDetailsPage extends StatefulWidget { final DepositEntity? deposit; const DepositDetailsPage({super.key, required this.deposit}); @override State<DepositDetailsPage> createState() => _DepositDetailsPageState(); }
class _DepositDetailsPageState extends State<DepositDetailsPage> {
  bool _deleting = false;
  String _date(DateTime? value) => value == null ? 'Not set' : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  Future<void> _delete(DepositEntity deposit) async { final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Delete Deposit?'), content: const Text('This action cannot be undone.'), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(dialogContext, true), style: TextButton.styleFrom(foregroundColor: AppColors.error), child: const Text('Delete'))])); if (confirmed == true && deposit.id != null && mounted) { setState(() => _deleting = true); context.read<DepositCubit>().deleteDeposit(deposit.id!); } }
  @override Widget build(BuildContext context) { final deposit = widget.deposit; if (deposit == null) return const Scaffold(body: Center(child: Text('Deposit data not found.'))); return BlocListener<DepositCubit, DepositState>(listener: (context, state) { if (state is DepositError) { setState(() => _deleting = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message))); } else if (_deleting && (state is DepositLoaded || state is DepositEmpty)) context.pop(true); }, child: Scaffold(appBar: AppBar(title: const Text('Deposit Details'), actions: [IconButton(icon: const Icon(Icons.edit_outlined), tooltip: 'Edit', onPressed: () => context.pushNamed(AppRoutes.editDepositName, pathParameters: {'depositId': deposit.id!.toString()}, extra: deposit)), IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Delete', onPressed: _deleting ? null : () => _delete(deposit))]), body: ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [Card(child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Status: ${deposit.status}', style: Theme.of(context).textTheme.titleMedium), const Divider(), _Row('Stay ID', '${deposit.stayId}'), _Row('Deposit Amount', deposit.amount.toStringAsFixed(2)), _Row('Refunded Amount', deposit.refundedAmount.toStringAsFixed(2)), _Row('Received Date', _date(deposit.receivedDate)), _Row('Refund Date', _date(deposit.refundDate)), _Row('Created Date', _date(deposit.createdAt)), _Row('Updated Date', _date(deposit.updatedAt))])))]))); }
}
class _Row extends StatelessWidget { final String label; final String value; const _Row(this.label, this.value); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 155, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))), Expanded(child: Text(value))])); }
