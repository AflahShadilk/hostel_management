sealed class BackupResult {
  const BackupResult();
}

class BackupSuccess extends BackupResult {
  const BackupSuccess(this.message);

  final String message;
}

class BackupCancelled extends BackupResult {
  const BackupCancelled();
}

class BackupFailure extends BackupResult {
  const BackupFailure(this.message);

  final String message;
}

abstract interface class BackupRepository {
  Future<BackupResult> createBackup();

  Future<BackupResult> restoreBackup();
}
