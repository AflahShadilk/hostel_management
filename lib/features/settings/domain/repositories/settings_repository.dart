import '../entities/settings_entity.dart';

abstract interface class SettingsRepository {
  Future<SettingsEntity> getSettings();
  Future<SettingsEntity> updateSettings(SettingsEntity settings);
}
