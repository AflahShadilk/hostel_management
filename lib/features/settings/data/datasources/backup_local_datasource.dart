import '../../domain/repositories/backup_repository.dart';

abstract interface class BackupLocalDataSource {
  Future<BackupResult> createBackup();

  Future<BackupResult> restoreBackup();
}
