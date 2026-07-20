import '../../domain/entities/settings_entity.dart';
class SettingsModel extends SettingsEntity {
  const SettingsModel({required super.themeMode, required super.currencySymbol, required super.currencyCode, required super.dateFormat, required super.languageCode, required super.notificationsEnabled, required super.createdAt, required super.updatedAt});
  factory SettingsModel.fromMap(Map<String, Object?> map) => SettingsModel(themeMode: map['theme_mode'] as String, currencySymbol: map['currency_symbol'] as String, currencyCode: map['currency_code'] as String, dateFormat: map['date_format'] as String, languageCode: map['language_code'] as String, notificationsEnabled: (map['notifications_enabled'] as num).toInt() == 1, createdAt: DateTime.parse(map['created_at'] as String), updatedAt: DateTime.parse(map['updated_at'] as String));
  factory SettingsModel.fromEntity(SettingsEntity value) => SettingsModel(themeMode: value.themeMode, currencySymbol: value.currencySymbol, currencyCode: value.currencyCode, dateFormat: value.dateFormat, languageCode: value.languageCode, notificationsEnabled: value.notificationsEnabled, createdAt: value.createdAt, updatedAt: value.updatedAt);
  Map<String, Object?> toMap() => {'theme_mode': themeMode, 'currency_symbol': currencySymbol, 'currency_code': currencyCode, 'date_format': dateFormat, 'language_code': languageCode, 'notifications_enabled': notificationsEnabled ? 1 : 0, 'created_at': createdAt.toIso8601String(), 'updated_at': updatedAt.toIso8601String()};
  SettingsEntity toEntity() => this;
}
