import '../models/settings_model.dart';

abstract interface class SettingsLocalDataSource {
  Future<SettingsModel> getSettings();
  Future<SettingsModel> updateSettings(SettingsModel settings);
}
