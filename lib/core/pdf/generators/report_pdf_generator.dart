import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/report_pdf_data.dart';

/// Builds printable report bytes without saving, sharing, or UI concerns.
class ReportPdfGenerator {
  const ReportPdfGenerator();

  Future<Uint8List> generate(ReportPdfData data) async {
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        header: (_) => _header(data),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (_) => <pw.Widget>[
          if (data.periodLabel?.isNotEmpty ?? false) ...<pw.Widget>[
            pw.Text(
              data.periodLabel!,
              style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 16),
          ],
          if (data.summary.isNotEmpty) ...<pw.Widget>[
            pw.Wrap(
              spacing: 12,
              runSpacing: 12,
              children: data.summary
                  .map(
                    (item) => pw.Container(
                      width: 150,
                      padding: pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue50,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: <pw.Widget>[
                          pw.Text(
                            item.label,
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            item.value,
                            style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
            pw.SizedBox(height: 20),
          ],
          if (data.tableHeaders.isNotEmpty) _table(data),
          ...data.sections.map(_section),
          if (data.footerNote?.isNotEmpty ?? false) ...<pw.Widget>[
            pw.SizedBox(height: 18),
            pw.Text(
              data.footerNote!,
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ],
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _header(ReportPdfData data) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              if (data.logoBytes != null) ...<pw.Widget>[
                pw.Container(
                  width: 40,
                  height: 40,
                  margin: pw.EdgeInsets.only(right: 10),
                  child: pw.Image(pw.MemoryImage(data.logoBytes!)),
                ),
              ],
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: <pw.Widget>[
                    if (data.organizationName?.isNotEmpty ?? false)
                      pw.Text(
                        data.organizationName!,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey800,
                        ),
                      ),
                    pw.Text(
                      data.title,
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (data.subtitle?.isNotEmpty ?? false) ...<pw.Widget>[
            pw.SizedBox(height: 4),
            pw.Text(
              data.subtitle!,
              style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
            ),
          ],
          pw.SizedBox(height: 6),
          pw.Text(
            'Generated: ${_formatDate(data.generatedAt)}',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 14),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 14),
        ],
      );

  pw.Widget _section(ReportPdfTableSection section) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.SizedBox(height: 18),
          pw.Text(
            section.title,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: section.headers,
            data: section.rows,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration:
                pw.BoxDecoration(color: PdfColors.blueGrey700),
            cellStyle: pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: pw.EdgeInsets.all(6),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          ),
        ],
      );

  pw.Widget _table(ReportPdfData data) => pw.TableHelper.fromTextArray(
        headers: data.tableHeaders,
        data: data.tableRows,
        headerStyle: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        headerDecoration: pw.BoxDecoration(color: PdfColors.blueGrey700),
        cellStyle: pw.TextStyle(fontSize: 9),
        cellAlignment: pw.Alignment.centerLeft,
        cellPadding: pw.EdgeInsets.all(6),
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      );

  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year} '
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}
