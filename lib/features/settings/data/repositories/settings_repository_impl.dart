import '../../domain/entities/settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';
import '../models/settings_model.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._dataSource);
  final SettingsLocalDataSource _dataSource;
  @override
  Future<SettingsEntity> getSettings() async =>
      (await _dataSource.getSettings()).toEntity();
  @override
  Future<SettingsEntity> updateSettings(SettingsEntity settings) =>
      _dataSource.updateSettings(SettingsModel.fromEntity(settings));
}
