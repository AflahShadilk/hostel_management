import 'dart:typed_data';

import 'package:printing/printing.dart';

import '../../../../core/pdf/services/pdf_service.dart';
import '../../../../core/pdf/services/pdf_share_service.dart';
import '../../../../core/pdf/services/pdf_storage_service.dart';
import '../../../hostel/domain/entities/hostel_entity.dart';
import '../../domain/entities/receipt_entity.dart';
import '../mappers/receipt_pdf_data_mapper.dart';

/// Coordinates receipt PDF actions without exposing PDF APIs to receipt data.
class ReceiptPdfExportService {
  const ReceiptPdfExportService(
    this._pdfService,
    this._pdfStorageService,
    this._pdfShareService,
    this._mapper,
  );

  static const _receiptsFolder = 'Hostel Management/Receipts';

  final PdfService _pdfService;
  final PdfStorageService _pdfStorageService;
  final PdfShareService _pdfShareService;
  final ReceiptPdfDataMapper _mapper;

  Future<void> preview({
    required ReceiptEntity receipt,
    HostelEntity? hostel,
  }) async {
    final bytes = await _generate(receipt: receipt, hostel: hostel);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> share({
    required ReceiptEntity receipt,
    HostelEntity? hostel,
  }) async {
    final filePath = await _save(receipt: receipt, hostel: hostel);
    await _pdfShareService.sharePdf(
      filePath: filePath,
      subject: 'Receipt ${receipt.receiptNumber}',
    );
  }

  Future<String> save({
    required ReceiptEntity receipt,
    HostelEntity? hostel,
  }) =>
      _save(receipt: receipt, hostel: hostel);

  Future<String> _save({
    required ReceiptEntity receipt,
    HostelEntity? hostel,
  }) async {
    final bytes = await _generate(receipt: receipt, hostel: hostel);
    return _pdfStorageService.savePdf(
      bytes: bytes,
      fileName: _mapper.fileName(receipt),
      folderName: _receiptsFolder,
    );
  }

  Future<Uint8List> _generate({
    required ReceiptEntity receipt,
    HostelEntity? hostel,
  }) =>
      _pdfService.generateReceipt(_mapper.map(receipt: receipt, hostel: hostel));
}
