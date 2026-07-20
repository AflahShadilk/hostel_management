enum ExportDataType {
  tenantCsv,
  roomCsv,
  rentCsv,
  expenseCsv,
  tenantPdf,
  rentPdf,
  expensePdf,
}

sealed class ExportResult {
  const ExportResult();
}

class ExportSuccess extends ExportResult {
  const ExportSuccess(this.message);

  final String message;
}

class ExportCancelled extends ExportResult {
  const ExportCancelled();
}

class ExportFailure extends ExportResult {
  const ExportFailure(this.message);

  final String message;
}

abstract interface class ExportRepository {
  Future<ExportResult> export(ExportDataType type);
}
