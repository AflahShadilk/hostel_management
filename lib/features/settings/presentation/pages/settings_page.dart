import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/database/database_constants.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../domain/entities/settings_entity.dart';
import '../../domain/repositories/export_repository.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/settings_state.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final Future<PackageInfo> _packageInfo;

  @override
  void initState() {
    super.initState();
    _packageInfo = PackageInfo.fromPlatform();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SettingsCubit>().loadSettings();
    });
  }

  void _save(SettingsEntity value) {
    context.read<SettingsCubit>().updateSettings(value);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsCubit, SettingsState>(
      listener: (context, state) {
        final message = switch (state) {
          SettingsError(:final message) ||
          SettingsOperationError(:final message) ||
          SettingsOperationSuccess(:final message) => message,
          _ => null,
        };
        if (message != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            if (state is SettingsInitial || state is SettingsLoading) {
              return const Center(child: AppLoadingIndicator());
            }
            if (state is SettingsError) {
              return const Center(child: Text('Unable to load settings.'));
            }
            if (state is! SettingsLoaded) return const SizedBox.shrink();

            final settings = state.settings;
            final isProcessing = state is SettingsOperationInProgress;
            return LayoutBuilder(
              builder: (context, constraints) {
                final padding = constraints.maxWidth >= 700 ? 32.0 : 16.0;
                return ListView(
                  padding: EdgeInsets.all(padding),
                  children: [
                    if (isProcessing) const LinearProgressIndicator(),
                    if (isProcessing) const SizedBox(height: 16),
                    SettingsSection(
                      title: 'General',
                      child: Column(
                        children: [
                          SettingsTile(
                            title: 'Theme',
                            trailing: DropdownButton<String>(
                              value: settings.themeMode,
                              items: const ['system', 'light', 'dark']
                                  .map(
                                    (value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(value),
                                    ),
                                  )
                                  .toList(),
                              onChanged: isProcessing
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        _save(settings.copyWith(
                                          themeMode: value,
                                        ));
                                      }
                                    },
                            ),
                          ),
                          SettingsTile(
                            title: 'Currency symbol',
                            trailing: SizedBox(
                              width: 72,
                              child: TextFormField(
                                initialValue: settings.currencySymbol,
                                textAlign: TextAlign.end,
                                onFieldSubmitted: (value) {
                                  if (value.trim().isNotEmpty) {
                                    _save(settings.copyWith(
                                      currencySymbol: value.trim(),
                                    ));
                                  }
                                },
                              ),
                            ),
                          ),
                          SettingsTile(
                            title: 'Currency code',
                            trailing: SizedBox(
                              width: 72,
                              child: TextFormField(
                                initialValue: settings.currencyCode,
                                textAlign: TextAlign.end,
                                onFieldSubmitted: (value) {
                                  if (value.trim().isNotEmpty) {
                                    _save(settings.copyWith(
                                      currencyCode: value.trim().toUpperCase(),
                                    ));
                                  }
                                },
                              ),
                            ),
                          ),
                          SettingsTile(
                            title: 'Date format',
                            trailing: DropdownButton<String>(
                              value: settings.dateFormat,
                              items: const [
                                'dd/MM/yyyy',
                                'MM/dd/yyyy',
                                'yyyy-MM-dd',
                              ]
                                  .map(
                                    (value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(value),
                                    ),
                                  )
                                  .toList(),
                              onChanged: isProcessing
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        _save(settings.copyWith(
                                          dateFormat: value,
                                        ));
                                      }
                                    },
                            ),
                          ),
                          SettingsTile(
                            title: 'Language code',
                            trailing: SizedBox(
                              width: 72,
                              child: TextFormField(
                                initialValue: settings.languageCode,
                                textAlign: TextAlign.end,
                                onFieldSubmitted: (value) {
                                  if (value.trim().isNotEmpty) {
                                    _save(settings.copyWith(
                                      languageCode: value.trim(),
                                    ));
                                  }
                                },
                              ),
                            ),
                          ),
                          SettingsTile(
                            title: 'Notifications',
                            trailing: Switch(
                              value: settings.notificationsEnabled,
                              onChanged: isProcessing
                                  ? null
                                  : (value) => _save(settings.copyWith(
                                        notificationsEnabled: value,
                                      )),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SettingsSection(
                      title: 'Backup & Restore',
                      child: Column(
                        children: [
                          SettingsTile(
                            title: 'Create backup',
                            subtitle: 'Save a local copy of the database.',
                            trailing: FilledButton(
                              onPressed: isProcessing
                                  ? null
                                  : () => context
                                      .read<SettingsCubit>()
                                      .createBackup(),
                              child: const Text('Backup'),
                            ),
                          ),
                          SettingsTile(
                            title: 'Restore backup',
                            subtitle: 'Replace the current local database.',
                            trailing: FilledButton.tonal(
                              onPressed: isProcessing
                                  ? null
                                  : () => _confirmRestore(context),
                              child: const Text('Restore'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SettingsSection(
                      title: 'Export Data',
                      child: Column(
                        children: [
                          _exportTile('Export Tenant CSV', ExportDataType.tenantCsv, isProcessing),
                          _exportTile('Export Room CSV', ExportDataType.roomCsv, isProcessing),
                          _exportTile('Export Rent CSV', ExportDataType.rentCsv, isProcessing),
                          _exportTile('Export Expense CSV', ExportDataType.expenseCsv, isProcessing),
                          _exportTile('Export Tenant PDF', ExportDataType.tenantPdf, isProcessing),
                          _exportTile('Export Rent PDF', ExportDataType.rentPdf, isProcessing),
                          _exportTile('Export Expense PDF', ExportDataType.expensePdf, isProcessing),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _aboutSection(context),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _aboutSection(BuildContext context) {
    return SettingsSection(
      title: 'About',
      child: FutureBuilder<PackageInfo>(
        future: _packageInfo,
        builder: (context, snapshot) {
          final packageInfo = snapshot.data;
          final version = packageInfo != null
              ? 'Version ${packageInfo.version} (${packageInfo.buildNumber})'
              : snapshot.hasError
                  ? 'Version information unavailable'
                  : 'Loading version information...';
          return Column(
            children: [
              SettingsTile(
                title: 'Hostel Management System',
                subtitle: version,
                trailing: const Icon(Icons.info_outline),
              ),
              SettingsTile(
                title: 'Database',
                subtitle: 'Version ${DatabaseConstants.databaseVersion}',
                trailing: const Icon(Icons.storage_outlined),
              ),
              SettingsTile(
                title: 'Developer',
                subtitle: 'Hostel Management Team',
                trailing: const Icon(Icons.code_outlined),
              ),
              SettingsTile(
                title: 'Copyright',
                subtitle: 'Copyright ${DateTime.now().year} Hostel Management System',
                trailing: const Icon(Icons.copyright_outlined),
              ),
              SettingsTile(
                title: 'Open-source licenses',
                subtitle: 'View licenses for packages used by this app.',
                trailing: FilledButton.tonal(
                  onPressed: () => showLicensePage(
                    context: context,
                    applicationName: 'Hostel Management System',
                    applicationVersion: packageInfo == null
                        ? null
                        : '${packageInfo.version} (${packageInfo.buildNumber})',
                  ),
                  child: const Text('View'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _exportTile(String title, ExportDataType type, bool isProcessing) {
    return SettingsTile(
      title: title,
      trailing: FilledButton.tonal(
        onPressed: isProcessing
            ? null
            : () => context.read<SettingsCubit>().exportData(type),
        child: const Text('Export'),
      ),
    );
  }

  Future<void> _confirmRestore(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore backup?'),
        content: const Text('This will replace the current local database.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<SettingsCubit>().restoreBackup();
    }
  }
}
