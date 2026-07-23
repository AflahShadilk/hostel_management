import 'dart:io';
import 'dart:typed_data';

import 'package:printing/printing.dart';

import '../../../../core/pdf/services/pdf_service.dart';
import '../../../../core/pdf/services/pdf_share_service.dart';
import '../../../../core/pdf/services/pdf_storage_service.dart';
import '../cubit/profit_loss_state.dart';
import '../mappers/profit_loss_pdf_data_mapper.dart';

/// Coordinates the P&L export actions while keeping widgets independent from
/// PDF, file-system, and platform APIs.
class ProfitLossPdfExportService {
  const ProfitLossPdfExportService(
    this._pdfService,
    this._pdfStorageService,
    this._pdfShareService,
    this._mapper,
  );

  static const _reportsFolder = 'Hostel Management/Reports';

  final PdfService _pdfService;
  final PdfStorageService _pdfStorageService;
  final PdfShareService _pdfShareService;
  final ProfitLossPdfDataMapper _mapper;

  Future<void> preview({
    required ProfitLossState state,
    required String hostelName,
    String? logoPath,
  }) async {
    final bytes = await _generate(
      state: state,
      hostelName: hostelName,
      logoPath: logoPath,
    );
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> share({
    required ProfitLossState state,
    required String hostelName,
    String? logoPath,
  }) async {
    final path = await _save(
      state: state,
      hostelName: hostelName,
      logoPath: logoPath,
    );
    await _pdfShareService.sharePdf(
      filePath: path,
      subject: 'Profit & Loss Report',
    );
  }

  Future<String> save({
    required ProfitLossState state,
    required String hostelName,
    String? logoPath,
  }) =>
      _save(
        state: state,
        hostelName: hostelName,
        logoPath: logoPath,
      );

  Future<String> _save({
    required ProfitLossState state,
    required String hostelName,
    String? logoPath,
  }) async {
    final bytes = await _generate(
      state: state,
      hostelName: hostelName,
      logoPath: logoPath,
    );
    return _pdfStorageService.savePdf(
      bytes: bytes,
      fileName: _mapper.fileName(state),
      folderName: _reportsFolder,
    );
  }

  Future<Uint8List> _generate({
    required ProfitLossState state,
    required String hostelName,
    String? logoPath,
  }) async {
    final logoBytes = await _loadLogo(logoPath);
    final data = _mapper.map(
      state: state,
      hostelName: hostelName,
      logoBytes: logoBytes,
    );
    return _pdfService.generateReport(data);
  }

  Future<Uint8List?> _loadLogo(String? logoPath) async {
    if (logoPath == null || logoPath.trim().isEmpty) return null;

    try {
      final logoFile = File(logoPath);
      if (!await logoFile.exists()) return null;
      return logoFile.readAsBytes();
    } on FileSystemException {
      return null;
    }
  }
}
