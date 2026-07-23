import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/pdf/widgets/export_pdf_bottom_sheet.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../hostel/domain/entities/hostel_entity.dart';
import '../../../../hostel/presentation/cubit/hostel_cubit.dart';
import '../../../domain/entities/receipt_entity.dart';
import '../../../../communication/domain/repositories/communication_repository.dart';
import '../../cubit/receipt/receipt_cubit.dart';
import '../../cubit/receipt/receipt_state.dart';
import '../../cubit/ui/deleting_cubit.dart';
import '../../services/receipt_pdf_export_service.dart';

class ReceiptDetailsPage extends StatefulWidget {
  final ReceiptEntity? receipt;
  const ReceiptDetailsPage({super.key, required this.receipt});
  @override
  State<ReceiptDetailsPage> createState() => _ReceiptDetailsPageState();
}

class _ReceiptDetailsPageState extends State<ReceiptDetailsPage> {
  String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
  Future<void> _delete(BuildContext context, ReceiptEntity receipt) async {
    final deletingCubit = context.read<DeletingCubit>();
    final mainCubit = context.read<ReceiptCubit>();
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
                title: const Text('Delete Receipt?'),
                content: const Text('This action cannot be undone.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.error),
                      child: const Text('Delete')),
                ]));
    if (confirmed == true && receipt.id != null) {
      deletingCubit.start();
      mainCubit.deleteReceipt(receipt.id!);
    }
  }

  Future<void> _shareReceipt(ReceiptEntity receipt) async {
    final result = await getIt<CommunicationRepository>().shareReceiptText(
      'Receipt ${receipt.receiptNumber}\n'
      'Payment ID: ${receipt.paymentId}\n'
      'Amount: ${receipt.paymentAmountSnapshot.toStringAsFixed(2)}\n'
      'Method: ${receipt.paymentMethodSnapshot}\n'
      'Issued: ${_date(receipt.issuedAt)}',
    );
    if (!mounted || result.isSuccess) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message ?? 'Unable to share receipt.')),
    );
  }

  void _showPdfExportSheet(ReceiptEntity receipt) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => ExportPdfBottomSheet(
        onExportPdf: () {
          Navigator.pop(sheetContext);
          _previewPdf(receipt);
        },
        onSharePdf: () {
          Navigator.pop(sheetContext);
          _sharePdf(receipt);
        },
        onSavePdf: () {
          Navigator.pop(sheetContext);
          _savePdf(receipt);
        },
      ),
    );
  }

  Future<void> _previewPdf(ReceiptEntity receipt) => _runPdfExport(
        (service, hostel) => service.preview(receipt: receipt, hostel: hostel),
      );

  Future<void> _sharePdf(ReceiptEntity receipt) => _runPdfExport(
        (service, hostel) => service.share(receipt: receipt, hostel: hostel),
      );

  Future<void> _savePdf(ReceiptEntity receipt) => _runPdfExport(
        (service, hostel) async {
          await service.save(receipt: receipt, hostel: hostel);
        },
        successMessage: 'Receipt saved to Hostel Management/Receipts.',
      );

  Future<void> _runPdfExport(
    Future<void> Function(
      ReceiptPdfExportService service,
      HostelEntity? hostel,
    ) action, {
    String? successMessage,
  }) async {
    final hostel = context.read<HostelCubit>().state.hostel;
    try {
      await action(getIt<ReceiptPdfExportService>(), hostel);
      if (!mounted || successMessage == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to export the receipt.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final receipt = widget.receipt;
    if (receipt == null) {
      return const Scaffold(
        body: Center(child: Text('Receipt data not found.')),
      );
    }
    return BlocProvider<DeletingCubit>(
      create: (_) => DeletingCubit(),
      child: Builder(builder: (context) {
        return BlocListener<ReceiptCubit, ReceiptState>(
            listener: (context, state) {
              if (state is ReceiptError) {
                context.read<DeletingCubit>().stop();
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(state.message)));
              } else if (context.read<DeletingCubit>().state &&
                  (state is ReceiptLoaded || state is ReceiptEmpty)) {
                context.pop(true);
              }
            },
            child: Scaffold(
              appBar: AppBar(title: const Text('Receipt Details'), actions: [
                IconButton(
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    tooltip: 'Export PDF',
                    onPressed: () => _showPdfExportSheet(receipt)),
                IconButton(
                    icon: const Icon(Icons.share_outlined),
                    tooltip: 'Share Receipt',
                    onPressed: () => _shareReceipt(receipt)),
                IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit',
                    onPressed: () => context.pushNamed(
                        AppRoutes.editReceiptName,
                        pathParameters: {'receiptId': receipt.id!.toString()},
                        extra: receipt)),
                BlocBuilder<DeletingCubit, bool>(
                  builder: (context, deleting) => IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete',
                    onPressed:
                        deleting ? null : () => _delete(context, receipt),
                  ),
                ),
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
                                Text(receipt.receiptNumber,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                const Divider(),
                                _Row('Receipt Number', receipt.receiptNumber),
                                _Row('Payment ID', '${receipt.paymentId}'),
                                _Row(
                                    'Payment Amount',
                                    receipt.paymentAmountSnapshot
                                        .toStringAsFixed(2)),
                                _Row('Payment Method',
                                    receipt.paymentMethodSnapshot),
                                _Row('Issued Date', _date(receipt.issuedAt)),
                                _Row('Created Date', _date(receipt.createdAt)),
                                _Row('Updated Date', _date(receipt.updatedAt)),
                              ])))
                ],
              ),
            ));
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
