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
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/hostel/domain/repositories/hostel_repository.dart';
import '../../features/hostel/data/repositories/hostel_repository_impl.dart';
import '../../features/hostel/presentation/cubit/hostel_cubit.dart';
import '../../features/room/domain/repositories/room_repository.dart';
import '../../features/room/data/repositories/room_repository_impl.dart';
import '../../features/room/domain/repositories/bed_repository.dart';
import '../../features/room/data/repositories/bed_repository_impl.dart';

import '../../features/room/domain/repositories/room_management_repository.dart';
import '../../features/room/data/repositories/room_management_repository_impl.dart';
import '../../features/room/presentation/cubit/room_cubit.dart';
import '../../features/room/presentation/cubit/bed_cubit.dart';
import '../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../features/dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../features/tenant/domain/repositories/tenant_repository.dart';
import '../../features/tenant/data/repositories/tenant_repository_impl.dart';
import '../../features/tenant/domain/repositories/tenant_management_repository.dart';
import '../../features/tenant/data/repositories/tenant_management_repository_impl.dart';
import '../../features/tenant/presentation/cubit/tenant_cubit.dart';
import '../../features/tenant/presentation/cubit/bed_selection_cubit.dart';

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

  getIt.registerFactory<AuthCubit>(
    () => AuthCubit(
      getIt<AuthRepository>(),
      getIt<AuthSecurityService>(),
      getIt<AuthSessionService>(),
    ),
  );

  getIt.registerLazySingleton<HostelRepository>(
    () => HostelRepositoryImpl(getIt<AppDatabase>()),
  );

  getIt.registerLazySingleton<RoomRepository>(
    () => RoomRepositoryImpl(getIt<AppDatabase>()),
  );

  getIt.registerLazySingleton<BedRepository>(
    () => BedRepositoryImpl(getIt<AppDatabase>()),
  );

  getIt.registerFactory<HostelCubit>(
    () => HostelCubit(getIt<HostelRepository>()),
  );
  getIt.registerLazySingleton<RoomManagementRepository>(
    () => RoomManagementRepositoryImpl(getIt<AppDatabase>()),
  );

  getIt.registerFactory<RoomCubit>(
    () => RoomCubit(getIt<RoomRepository>(), getIt<RoomManagementRepository>()),
  );

  getIt.registerFactory<BedCubit>(
    () => BedCubit(getIt<BedRepository>(), getIt<RoomRepository>()),
  );

  getIt.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(getIt<AppDatabase>()),
  );

  getIt.registerFactory<DashboardCubit>(
    () => DashboardCubit(getIt<DashboardRepository>()),
  );

  getIt.registerLazySingleton<TenantRepository>(
    () => TenantRepositoryImpl(getIt<AppDatabase>()),
  );

  getIt.registerLazySingleton<TenantManagementRepository>(
    () => TenantManagementRepositoryImpl(
      getIt<AppDatabase>(),
      getIt<TenantRepository>(),
      getIt<BedRepository>(),
      getIt<RoomManagementRepository>(),
    ),
  );

  getIt.registerFactory<TenantCubit>(
    () => TenantCubit(
      getIt<TenantRepository>(),
      getIt<TenantManagementRepository>(),
      getIt<RoomRepository>(),
      getIt<BedRepository>(),
    ),
  );

  getIt.registerFactory<BedSelectionCubit>(
    () => BedSelectionCubit(
      getIt<RoomRepository>(),
      getIt<BedRepository>(),
    ),
  );
}
