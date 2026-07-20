import '../../domain/repositories/export_repository.dart';

abstract interface class ExportLocalDataSource {
  Future<ExportResult> export(ExportDataType type);
}
