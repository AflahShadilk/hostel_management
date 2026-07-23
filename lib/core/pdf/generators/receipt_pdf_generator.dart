import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/receipt_pdf_data.dart';

/// Builds printable receipt bytes without saving, sharing, or UI concerns.
class ReceiptPdfGenerator {
  const ReceiptPdfGenerator();

  Future<Uint8List> generate(ReceiptPdfData data) async {
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (_) => <pw.Widget>[
          _header(data),
          pw.SizedBox(height: 24),
          _recipient(data),
          pw.SizedBox(height: 20),
          _lineItems(data),
          pw.SizedBox(height: 16),
          _total(data),
          if (data.notes?.isNotEmpty ?? false) ...<pw.Widget>[
            pw.SizedBox(height: 20),
            pw.Text(
              'Notes',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(data.notes!, style: pw.TextStyle(fontSize: 10)),
          ],
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _header(ReceiptPdfData data) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: <pw.Widget>[
                    pw.Text(
                      data.businessName,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (data.businessAddress?.isNotEmpty ?? false)
                      pw.Text(
                        data.businessAddress!,
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    if (data.businessPhone?.isNotEmpty ?? false)
                      pw.Text(
                        data.businessPhone!,
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: <pw.Widget>[
                  pw.Text(
                    data.title,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey800,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'No. ${data.documentNumber}',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    _formatDate(data.issuedAt),
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Divider(color: PdfColors.grey300),
        ],
      );

  pw.Widget _recipient(ReceiptPdfData data) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(
            'Received from',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            data.recipientName,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          if (data.recipientDetails?.isNotEmpty ?? false)
            pw.Text(
              data.recipientDetails!,
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
        ],
      );

  pw.Widget _lineItems(ReceiptPdfData data) => pw.TableHelper.fromTextArray(
        headers: const <String>['Description', 'Details', 'Amount'],
        data: data.lineItems
            .map(
              (item) => <String>[
                item.description,
                item.detail ?? '',
                _amount(data, item.amount),
              ],
            )
            .toList(growable: false),
        headerStyle: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        headerDecoration: pw.BoxDecoration(color: PdfColors.blueGrey700),
        cellStyle: pw.TextStyle(fontSize: 10),
        cellAlignment: pw.Alignment.centerLeft,
        cellPadding: pw.EdgeInsets.all(7),
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      );

  pw.Widget _total(ReceiptPdfData data) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Container(
          width: 220,
          padding: pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: <pw.Widget>[
              pw.Text(
                data.totalLabel,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                _amount(data, data.totalAmount),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ),
      );

  String _amount(ReceiptPdfData data, double amount) =>
      '${data.currencyPrefix}${amount.toStringAsFixed(2)}';

  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}
