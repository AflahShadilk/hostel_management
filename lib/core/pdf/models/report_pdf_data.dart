import 'dart:typed_data';

/// Export-ready content for a tabular report PDF.
///
/// This model deliberately contains only presentation values so it can be
/// assembled by any feature without coupling the PDF layer to business types.
class ReportPdfData {
  const ReportPdfData({
    required this.title,
    required this.generatedAt,
    this.subtitle,
    this.organizationName,
    this.logoBytes,
    this.periodLabel,
    this.summary = const <ReportPdfSummaryItem>[],
    this.tableHeaders = const <String>[],
    this.tableRows = const <List<String>>[],
    this.sections = const <ReportPdfTableSection>[],
    this.footerNote,
  });

  final String title;
  final DateTime generatedAt;
  final String? subtitle;
  final String? organizationName;
  final Uint8List? logoBytes;
  final String? periodLabel;
  final List<ReportPdfSummaryItem> summary;
  final List<String> tableHeaders;
  final List<List<String>> tableRows;
  final List<ReportPdfTableSection> sections;
  final String? footerNote;
}

/// A concise label/value item displayed in the report summary.
class ReportPdfSummaryItem {
  const ReportPdfSummaryItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

/// A titled table that can appear in any export-ready report.
class ReportPdfTableSection {
  const ReportPdfTableSection({
    required this.title,
    required this.headers,
    required this.rows,
  });

  final String title;
  final List<String> headers;
  final List<List<String>> rows;
}
