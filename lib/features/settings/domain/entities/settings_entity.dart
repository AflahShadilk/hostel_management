import 'package:equatable/equatable.dart';

class SettingsEntity extends Equatable {
  const SettingsEntity(
      {required this.themeMode,
      required this.currencySymbol,
      required this.currencyCode,
      required this.dateFormat,
      required this.languageCode,
      required this.notificationsEnabled,
      required this.createdAt,
      required this.updatedAt});
  final String themeMode;
  final String currencySymbol;
  final String currencyCode;
  final String dateFormat;
  final String languageCode;
  final bool notificationsEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  SettingsEntity copyWith(
          {String? themeMode,
          String? currencySymbol,
          String? currencyCode,
          String? dateFormat,
          String? languageCode,
          bool? notificationsEnabled,
          DateTime? updatedAt}) =>
      SettingsEntity(
          themeMode: themeMode ?? this.themeMode,
          currencySymbol: currencySymbol ?? this.currencySymbol,
          currencyCode: currencyCode ?? this.currencyCode,
          dateFormat: dateFormat ?? this.dateFormat,
          languageCode: languageCode ?? this.languageCode,
          notificationsEnabled:
              notificationsEnabled ?? this.notificationsEnabled,
          createdAt: createdAt,
          updatedAt: updatedAt ?? this.updatedAt);
  @override
  List<Object?> get props => [
        themeMode,
        currencySymbol,
        currencyCode,
        dateFormat,
        languageCode,
        notificationsEnabled,
        createdAt,
        updatedAt
      ];
}
