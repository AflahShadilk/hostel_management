import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/backup_repository.dart';
import 'settings_state.dart';
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._repository, this._backupRepository) : super(const SettingsInitial());
  final SettingsRepository _repository;
  final BackupRepository _backupRepository;
  Future<void> loadSettings() async { emit(const SettingsLoading()); try { emit(SettingsLoaded(await _repository.getSettings())); } catch (error) { emit(SettingsError(error.toString())); } }
  Future<void> updateSettings(SettingsEntity settings) async { try { emit(SettingsLoaded(await _repository.updateSettings(settings.copyWith(updatedAt: DateTime.now())))); } catch (error) { emit(SettingsError(error.toString())); } }
  Future<void> createBackup() => _runOperation(_backupRepository.createBackup);
  Future<void> restoreBackup() => _runOperation(_backupRepository.restoreBackup, reloadSettings: true);
  Future<void> _runOperation(Future<BackupResult> Function() operation, {bool reloadSettings = false}) async { final currentState = state; if (currentState is! SettingsLoaded) return; final settings = currentState.settings; emit(SettingsOperationInProgress(settings)); final result = await operation(); if (result is BackupSuccess) { try { emit(SettingsOperationSuccess(reloadSettings ? await _repository.getSettings() : settings, result.message)); } catch (error) { emit(SettingsOperationError(settings, error.toString())); } } else if (result is BackupFailure) { emit(SettingsOperationError(settings, result.message)); } else { emit(SettingsLoaded(settings)); } }
}
