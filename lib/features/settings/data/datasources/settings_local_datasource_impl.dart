import '../../../../core/database/app_database.dart';
import '../models/settings_model.dart';
import 'settings_local_datasource.dart';
import 'settings_local_schema.dart';
class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  const SettingsLocalDataSourceImpl(this._database);
  final AppDatabase _database;
  @override Future<SettingsModel> getSettings() async { final rows = await (await _database.database).query(SettingsLocalSchema.table, limit: 1); if (rows.isEmpty) throw StateError('Application settings were not initialized.'); return SettingsModel.fromMap(rows.first); }
  @override Future<SettingsModel> updateSettings(SettingsModel settings) async { final count = await (await _database.database).update(SettingsLocalSchema.table, settings.toMap(), where: 'id = ?', whereArgs: const [1]); if (count != 1) throw StateError('Application settings update failed.'); return settings; }
}
