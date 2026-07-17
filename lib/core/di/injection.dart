import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../database/app_database.dart';
import '../services/secure_storage_service.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/data/services/credential_hash_service.dart';
import '../../features/auth/domain/services/auth_security_service.dart';
import '../../features/auth/data/services/auth_security_service_impl.dart';
import '../../features/auth/domain/services/auth_session_service.dart';
import '../../features/auth/data/services/auth_session_service_impl.dart';

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

  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt<AppDatabase>()),
  );

  getIt.registerLazySingleton<CredentialHashService>(
    () => const CredentialHashService(),
  );

  getIt.registerLazySingleton<AuthSecurityService>(
    () => AuthSecurityServiceImpl(
      getIt<SecureStorageService>(),
      getIt<CredentialHashService>(),
    ),
  );

  getIt.registerLazySingleton<AuthSessionService>(
    () => AuthSessionServiceImpl(getIt<SecureStorageService>()),
  );
}
