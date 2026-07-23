import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_constants.dart';
import '../../domain/repositories/backup_repository.dart';
import 'backup_local_datasource.dart';

class BackupLocalDataSourceImpl implements BackupLocalDataSource {
  const BackupLocalDataSourceImpl(this._appDatabase);

  final AppDatabase _appDatabase;

  @override
  Future<BackupResult> createBackup() async {
    try {
      final destination = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Choose backup destination',
      );
      if (destination == null) return const BackupCancelled();

      final databasePath = await _databasePath();
      final databaseFile = File(databasePath);
      if (!await databaseFile.exists()) {
        return const BackupFailure('The active database file was not found.');
      }

      final timestamp = DateTime.now();
      final fileName =
          'hostel_backup_${timestamp.year.toString().padLeft(4, '0')}'
          '${timestamp.month.toString().padLeft(2, '0')}'
          '${timestamp.day.toString().padLeft(2, '0')}_'
          '${timestamp.hour.toString().padLeft(2, '0')}'
          '${timestamp.minute.toString().padLeft(2, '0')}'
          '${timestamp.second.toString().padLeft(2, '0')}.db';
      final backupPath = path.join(destination, fileName);

      await _appDatabase.close();
      try {
        await databaseFile.copy(backupPath);
      } finally {
        await _appDatabase.reopen();
      }

      return BackupSuccess('Backup created at $backupPath.');
    } on FileSystemException catch (error) {
      return BackupFailure('Unable to create backup: ${error.message}');
    } catch (error) {
      return BackupFailure('Unable to create backup: $error');
    }
  }

  @override
  Future<BackupResult> restoreBackup() async {
    String? databasePath;
    String? rollbackPath;
    String? stagedPath;
    var connectionClosed = false;

    try {
      final selection = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['db'],
      );
      if (selection == null) return const BackupCancelled();

      final selectedPath = selection.files.single.path;
      if (selectedPath == null || !selectedPath.toLowerCase().endsWith('.db')) {
        return const BackupFailure('Select a readable .db backup file.');
      }

      final source = File(selectedPath);
      if (!await source.exists() || await source.length() == 0) {
        return const BackupFailure(
            'The selected backup file is missing or empty.');
      }
      await source.openRead(0, 1).first;

      databasePath = await _databasePath();
      final activeFile = File(databasePath);
      final directory = activeFile.parent;
      stagedPath = path.join(directory.path,
          '.restore_${DateTime.now().microsecondsSinceEpoch}.db');
      rollbackPath = path.join(directory.path,
          '.rollback_${DateTime.now().microsecondsSinceEpoch}.db');

      await _appDatabase.close();
      connectionClosed = true;

      await source.copy(stagedPath);
      await _validateDatabase(stagedPath);

      if (await activeFile.exists()) {
        await activeFile.copy(rollbackPath);
      }

      try {
        if (await activeFile.exists()) await activeFile.delete();
        await File(stagedPath).rename(databasePath);
        stagedPath = null;
      } catch (error) {
        await _restoreOriginal(databasePath, rollbackPath);
        return BackupFailure('Unable to replace the active database: $error');
      }

      try {
        await _appDatabase.reopen();
        connectionClosed = false;
      } catch (error) {
        await _appDatabase.close();
        await _restoreOriginal(databasePath, rollbackPath);
        await _appDatabase.reopen();
        connectionClosed = false;
        return BackupFailure(
            'The backup could not be opened. The original database was restored.');
      }

      return const BackupSuccess('Database restored successfully.');
    } on FileSystemException catch (error) {
      return BackupFailure('Unable to restore backup: ${error.message}');
    } catch (error) {
      return BackupFailure('Unable to restore backup: $error');
    } finally {
      if (connectionClosed) {
        try {
          await _appDatabase.reopen();
        } catch (_) {
          // The caller receives the restore failure and the original database
          // remains untouched whenever it could not be safely reopened.
        }
      }
      if (stagedPath != null) await _deleteIfPresent(stagedPath);
      if (rollbackPath != null) await _deleteIfPresent(rollbackPath);
    }
  }

  Future<String> _databasePath() async => path.join(
        await getDatabasesPath(),
        DatabaseConstants.databaseName,
      );

  Future<void> _validateDatabase(String databasePath) async {
    final database = await openDatabase(databasePath, readOnly: true);
    await database.close();
  }

  Future<void> _restoreOriginal(
      String databasePath, String rollbackPath) async {
    final rollback = File(rollbackPath);
    if (!await rollback.exists()) return;
    final replacement = File(databasePath);
    if (await replacement.exists()) await replacement.delete();
    await rollback.copy(databasePath);
  }

  Future<void> _deleteIfPresent(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // Temporary cleanup must not hide the result of the backup operation.
    }
  }
}
