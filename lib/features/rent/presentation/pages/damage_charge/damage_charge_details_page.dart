import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/damage_charge_entity.dart';
import '../../cubit/damage_charge/damage_charge_cubit.dart';
import '../../cubit/damage_charge/damage_charge_state.dart';

class DamageChargeDetailsPage extends StatefulWidget { final DamageChargeEntity? damageCharge; const DamageChargeDetailsPage({super.key, required this.damageCharge}); @override State<DamageChargeDetailsPage> createState() => _DamageChargeDetailsPageState(); }
class _DamageChargeDetailsPageState extends State<DamageChargeDetailsPage> {
  bool _deleting = false;
  String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  Future<void> _delete(DamageChargeEntity charge) async { final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Delete Damage Charge?'), content: const Text('This action cannot be undone.'), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(dialogContext, true), style: TextButton.styleFrom(foregroundColor: AppColors.error), child: const Text('Delete'))])); if (confirmed == true && charge.id != null && mounted) { setState(() => _deleting = true); context.read<DamageChargeCubit>().deleteDamageCharge(charge.id!); } }
  @override Widget build(BuildContext context) { final charge = widget.damageCharge; if (charge == null) return const Scaffold(body: Center(child: Text('Damage charge data not found.'))); return BlocListener<DamageChargeCubit, DamageChargeState>(listener: (context, state) { if (state is DamageChargeError) { setState(() => _deleting = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message))); } else if (_deleting && (state is DamageChargeLoaded || state is DamageChargeEmpty)) context.pop(true); }, child: Scaffold(appBar: AppBar(title: const Text('Damage Charge Details'), actions: [IconButton(icon: const Icon(Icons.edit_outlined), tooltip: 'Edit', onPressed: () => context.pushNamed(AppRoutes.editDamageChargeName, pathParameters: {'damageChargeId': charge.id!.toString()}, extra: charge)), IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Delete', onPressed: _deleting ? null : () => _delete(charge))]), body: ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [Card(child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Status: ${charge.status}', style: Theme.of(context).textTheme.titleMedium), const Divider(), _Row('Stay ID', '${charge.stayId}'), _Row('Description', charge.description), _Row('Amount', charge.amount.toStringAsFixed(2)), _Row('Created Date', _date(charge.createdAt)), _Row('Updated Date', _date(charge.updatedAt))])))]))); }
}
class _Row extends StatelessWidget { final String label; final String value; const _Row(this.label, this.value); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 145, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))), Expanded(child: Text(value))])); }
