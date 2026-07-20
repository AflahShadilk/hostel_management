import '../../domain/repositories/export_repository.dart';
import '../datasources/export_local_datasource.dart';

class ExportRepositoryImpl implements ExportRepository {
  const ExportRepositoryImpl(this._dataSource);

  final ExportLocalDataSource _dataSource;

  @override
  Future<ExportResult> export(ExportDataType type) => _dataSource.export(type);
}
