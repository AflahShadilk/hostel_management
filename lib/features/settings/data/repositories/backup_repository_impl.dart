import '../../domain/repositories/backup_repository.dart';
import '../datasources/backup_local_datasource.dart';

class BackupRepositoryImpl implements BackupRepository {
  const BackupRepositoryImpl(this._dataSource);

  final BackupLocalDataSource _dataSource;

  @override
  Future<BackupResult> createBackup() => _dataSource.createBackup();

  @override
  Future<BackupResult> restoreBackup() => _dataSource.restoreBackup();
}
