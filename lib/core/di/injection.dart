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
import '../../features/rent/data/datasources/rent_local_datasource.dart';
import '../../features/rent/data/datasources/rent_local_datasource_impl.dart';
import '../../features/rent/data/repositories/rent_repository_impl.dart';
import '../../features/rent/domain/repositories/rent_repository.dart';
import '../../features/rent/presentation/cubit/stay/stay_cubit.dart';
import '../../features/rent/presentation/cubit/rent_record/rent_record_cubit.dart';
import '../../features/rent/presentation/cubit/payment/payment_cubit.dart';
import '../../features/rent/presentation/cubit/receipt/receipt_cubit.dart';
import '../../features/rent/presentation/cubit/deposit/deposit_cubit.dart';
import '../../features/rent/presentation/cubit/damage_charge/damage_charge_cubit.dart';
import '../../features/rent/presentation/cubit/checkout/checkout_cubit.dart';
import '../../features/rent/presentation/cubit/checkout/checkout_summary_cubit.dart';
import '../../features/rent/domain/repositories/rent_collection_repository.dart';
import '../../features/rent/data/repositories/rent_collection_repository_impl.dart';
import '../../features/rent/presentation/cubit/rent_collection/rent_collection_cubit.dart';
import '../../features/rent/presentation/cubit/ui/submitting_cubit.dart';
import '../../features/rent/presentation/cubit/ui/deleting_cubit.dart';
import '../../features/rent/presentation/cubit/ui/selected_date_cubit.dart';
import '../../features/rent/presentation/cubit/ui/selected_status_cubit.dart';
import '../../features/rent/presentation/cubit/ui/balance_cubit.dart';
import '../../features/expense/data/datasources/expense_local_datasource.dart';
import '../../features/expense/data/datasources/expense_local_datasource_impl.dart';
import '../../features/expense/data/repositories/expense_repository_impl.dart';
import '../../features/expense/domain/repositories/expense_repository.dart';
import '../../features/expense/presentation/cubit/expense/expense_cubit.dart';
import '../../features/expense/presentation/cubit/expense_category/expense_category_cubit.dart';
import '../../features/communication/data/repositories/communication_repository_impl.dart';
import '../../features/communication/domain/repositories/communication_repository.dart';
import '../../features/search/data/repositories/search_repository_impl.dart';
import '../../features/search/domain/repositories/search_repository.dart';
import '../../features/search/presentation/cubit/search_cubit.dart';
import '../../features/settings/data/datasources/settings_local_datasource.dart';
import '../../features/settings/data/datasources/settings_local_datasource_impl.dart';
import '../../features/settings/data/datasources/backup_local_datasource.dart';
import '../../features/settings/data/datasources/backup_local_datasource_impl.dart';
import '../../features/settings/data/repositories/backup_repository_impl.dart';
import '../../features/settings/domain/repositories/backup_repository.dart';
import '../../features/settings/data/datasources/export_local_datasource.dart';
import '../../features/settings/data/datasources/export_local_datasource_impl.dart';
import '../../features/settings/data/repositories/export_repository_impl.dart';
import '../../features/settings/domain/repositories/export_repository.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';
import '../../features/financial_onboarding/presentation/cubit/financial_onboarding_cubit.dart';
import '../../features/reports/domain/repositories/reports_repository.dart';
import '../../features/reports/data/repositories/reports_repository_impl.dart';
import '../../features/reports/presentation/cubit/profit_loss_cubit.dart';

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
      getIt<RoomRepository>(),
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

  getIt.registerLazySingleton<RentLocalDataSource>(
    () => RentLocalDataSourceImpl(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<RentRepository>(
    () => RentRepositoryImpl(
      getIt<RentLocalDataSource>(),
      getIt<AppDatabase>(),
    ),
  );
  getIt.registerFactory<StayCubit>(() => StayCubit(getIt<RentRepository>()));
  getIt.registerFactory<RentRecordCubit>(
    () => RentRecordCubit(getIt<RentRepository>()),
  );
  
  getIt.registerLazySingleton<RentCollectionRepository>(
    () => RentCollectionRepositoryImpl(getIt<AppDatabase>()),
  );
  getIt.registerFactory<RentCollectionCubit>(
    () => RentCollectionCubit(
      getIt<RentCollectionRepository>(),
      getIt<RentRepository>(),
    ),
  );
  getIt.registerFactory<PaymentCubit>(
      () => PaymentCubit(getIt<RentRepository>()));
  getIt.registerFactory<ReceiptCubit>(
      () => ReceiptCubit(getIt<RentRepository>()));
  getIt.registerFactory<DepositCubit>(
      () => DepositCubit(getIt<RentRepository>()));
  getIt.registerFactory<DamageChargeCubit>(
    () => DamageChargeCubit(getIt<RentRepository>()),
  );
  getIt.registerFactory<CheckoutCubit>(
      () => CheckoutCubit(getIt<RentRepository>()));

  getIt.registerLazySingleton<ExpenseLocalDataSource>(
    () => ExpenseLocalDataSourceImpl(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<ExpenseRepository>(
    () => ExpenseRepositoryImpl(getIt<ExpenseLocalDataSource>()),
  );
  getIt.registerFactory<ExpenseCategoryCubit>(
    () => ExpenseCategoryCubit(getIt<ExpenseRepository>()),
  );
  getIt.registerFactory<ExpenseCubit>(
    () => ExpenseCubit(getIt<ExpenseRepository>()),
  );

  getIt.registerLazySingleton<CommunicationRepository>(
    () => const CommunicationRepositoryImpl(),
  );

  getIt.registerLazySingleton<SearchRepository>(
    () => SearchRepositoryImpl(getIt<AppDatabase>()),
  );
  getIt.registerFactory<SearchCubit>(
      () => SearchCubit(getIt<SearchRepository>()));
  getIt.registerLazySingleton<SettingsLocalDataSource>(() => SettingsLocalDataSourceImpl(getIt<AppDatabase>()));
  getIt.registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl(getIt<SettingsLocalDataSource>()));
  getIt.registerLazySingleton<BackupLocalDataSource>(
    () => BackupLocalDataSourceImpl(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<BackupRepository>(
    () => BackupRepositoryImpl(getIt<BackupLocalDataSource>()),
  );
  getIt.registerLazySingleton<ExportLocalDataSource>(
    () => ExportLocalDataSourceImpl(
      getIt<TenantRepository>(),
      getIt<RoomRepository>(),
      getIt<RentRepository>(),
      getIt<ExpenseRepository>(),
      getIt<HostelRepository>(),
      getIt<AuthSessionService>(),
    ),
  );
  getIt.registerLazySingleton<ExportRepository>(
    () => ExportRepositoryImpl(getIt<ExportLocalDataSource>()),
  );
  getIt.registerFactory<SettingsCubit>(
    () => SettingsCubit(
      getIt<SettingsRepository>(),
      getIt<BackupRepository>(),
      getIt<ExportRepository>(),
    ),
  );
  getIt.registerFactory<FinancialOnboardingCubit>(
    () => FinancialOnboardingCubit(getIt<RentRepository>()),
  );

  // Lightweight UI Cubits — no repository dependencies
  getIt.registerFactory<SubmittingCubit>(() => SubmittingCubit());
  getIt.registerFactory<DeletingCubit>(() => DeletingCubit());
  getIt.registerFactory<SelectedDateCubit>(() => SelectedDateCubit(null));
  getIt.registerFactory<SelectedStatusCubit>(() => SelectedStatusCubit(''));
  getIt.registerFactory<BalanceCubit>(() => BalanceCubit(0.0));
  getIt.registerFactory<CheckoutSummaryCubit>(() => CheckoutSummaryCubit(getIt<RentRepository>()));

  // Reports
  getIt.registerLazySingleton<ReportsRepository>(
    () => ReportsRepositoryImpl(getIt<AppDatabase>()),
  );
  getIt.registerFactory<ProfitLossCubit>(
    () => ProfitLossCubit(getIt<ReportsRepository>()),
  );
}




