import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../database/app_database.dart';
import '../services/secure_storage_service.dart';

/// Global access point for the service locator.
/// Feature modules import this to resolve their dependencies.
final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // AppDatabase.instance already holds the static singleton; registering it
  // here lets repositories resolve it through getIt without creating a second
  // connection.
  getIt.registerSingleton<AppDatabase>(AppDatabase.instance);

  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  getIt.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(getIt<FlutterSecureStorage>()),
  );
}
