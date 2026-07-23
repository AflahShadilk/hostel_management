import 'dart:typed_data';

import '../generators/receipt_pdf_generator.dart';
import '../generators/report_pdf_generator.dart';
import '../models/receipt_pdf_data.dart';
import '../models/report_pdf_data.dart';

/// Coordinates PDF generation while keeping storage and sharing separate.
class PdfService {
  const PdfService(
    this._reportPdfGenerator,
    this._receiptPdfGenerator,
  );

  final ReportPdfGenerator _reportPdfGenerator;
  final ReceiptPdfGenerator _receiptPdfGenerator;

  Future<Uint8List> generateReport(ReportPdfData data) =>
      _reportPdfGenerator.generate(data);

  Future<Uint8List> generateReceipt(ReceiptPdfData data) =>
      _receiptPdfGenerator.generate(data);
}
