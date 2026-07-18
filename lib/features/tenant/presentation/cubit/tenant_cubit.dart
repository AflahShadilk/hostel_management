import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/tenant_entity.dart';
import '../../domain/repositories/tenant_management_repository.dart';
import '../../domain/repositories/tenant_repository.dart';
import 'tenant_state.dart';

class TenantCubit extends Cubit<TenantState> {
  final TenantRepository _tenantRepository;
  final TenantManagementRepository _tenantManagementRepository;

  TenantCubit(
    this._tenantRepository,
    this._tenantManagementRepository,
  ) : super(const TenantState());

  Future<void> loadTenants() async {
    emit(state.copyWith(status: TenantOperationStatus.loading));
    try {
      final tenants = await _tenantRepository.getAllTenants();
      emit(state.copyWith(
        status: TenantOperationStatus.loaded,
        tenants: tenants,
        filteredTenants: _applySearch(tenants, state.searchQuery),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TenantOperationStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void search(String query) {
    final filtered = _applySearch(state.tenants, query);
    emit(state.copyWith(
      searchQuery: query,
      filteredTenants: filtered,
    ));
  }

  List<TenantEntity> _applySearch(List<TenantEntity> tenants, String query) {
    final trimmedQuery = query.trim().toLowerCase();
    if (trimmedQuery.isEmpty) return tenants;

    return tenants.where((t) {
      final matchName = t.fullName.toLowerCase().contains(trimmedQuery);
      final matchPhone = t.phoneNumber.toLowerCase().contains(trimmedQuery);
      final matchEmail =
          t.email != null && t.email!.toLowerCase().contains(trimmedQuery);
      return matchName || matchPhone || matchEmail;
    }).toList();
  }

  Future<void> createTenant(TenantEntity tenant) async {
    emit(state.copyWith(status: TenantOperationStatus.creating));
    try {
      await _tenantManagementRepository.assignTenant(tenant);
      await loadTenants();
    } catch (e) {
      emit(state.copyWith(
        status: TenantOperationStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> updateTenant(TenantEntity tenant) async {
    emit(state.copyWith(status: TenantOperationStatus.updating));
    try {
      await _tenantManagementRepository.updateTenantDetails(tenant);
      await loadTenants();
    } catch (e) {
      emit(state.copyWith(
        status: TenantOperationStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> deleteTenant(int tenantId, {required int bedId}) async {
    emit(state.copyWith(status: TenantOperationStatus.deleting));
    try {
      await _tenantManagementRepository.deleteTenant(tenantId, bedId: bedId);
      await loadTenants();
    } catch (e) {
      emit(state.copyWith(
        status: TenantOperationStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> checkOutTenant(int tenantId, {required int bedId}) async {
    emit(state.copyWith(status: TenantOperationStatus.checkingOut));
    try {
      await _tenantManagementRepository.checkOutTenant(tenantId, bedId: bedId);
      await loadTenants();
    } catch (e) {
      emit(state.copyWith(
        status: TenantOperationStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
