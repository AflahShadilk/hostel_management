import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/tenant_entity.dart';
import '../../domain/entities/tenant_registration_context.dart';
import '../../domain/repositories/tenant_management_repository.dart';
import '../../domain/repositories/tenant_repository.dart';
import '../../../room/domain/repositories/bed_repository.dart';
import '../../../room/domain/repositories/room_repository.dart';
import '../models/tenant_view_model.dart';
import 'tenant_state.dart';

class TenantCubit extends Cubit<TenantState> {
  final TenantRepository _tenantRepository;
  final TenantManagementRepository _tenantManagementRepository;
  final RoomRepository _roomRepository;
  final BedRepository _bedRepository;

  TenantCubit(
    this._tenantRepository,
    this._tenantManagementRepository,
    this._roomRepository,
    this._bedRepository,
  ) : super(const TenantState());

  Future<void> loadTenants() => _loadTenants();

  Future<void> _loadTenants({
    TenantRegistrationContext? registrationContext,
  }) async {
    emit(state.copyWith(status: TenantOperationStatus.loading));
    try {
      final tenants = await _tenantRepository.getAllTenants();
      final viewModels = await _resolveViewModels(tenants);
      emit(state.copyWith(
        status: TenantOperationStatus.loaded,
        tenants: tenants,
        filteredTenants: _applySearch(tenants, state.searchQuery),
        viewModels: viewModels,
        filteredViewModels: _applyViewModelSearch(viewModels, state.searchQuery),
        registrationContext: registrationContext,
        clearRegistrationContext: registrationContext == null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TenantOperationStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Resolves room and bed display labels for each tenant using the repositories.
  /// This follows Clean Architecture — the Cubit fetches and maps data, not the widget.
  Future<List<TenantViewModel>> _resolveViewModels(List<TenantEntity> tenants) async {
    final result = <TenantViewModel>[];
    for (final tenant in tenants) {
      if (tenant.bedId == null) {
        result.add(TenantViewModel(
          tenant: tenant,
          roomName: 'â€”',
          bedName: 'â€”',
        ));
        continue;
      }

      final bed = await _bedRepository.getBedById(tenant.bedId!);
      String bedName = '—';
      String roomName = '—';
      if (bed != null) {
        bedName = 'Bed ${bed.bedNumber}';
        if (bed.roomId > 0) {
          final room = await _roomRepository.getRoomById(bed.roomId);
          if (room != null) {
            roomName = 'Room ${room.roomNumber}';
          }
        }
      }
      result.add(TenantViewModel(
        tenant: tenant,
        roomName: roomName,
        bedName: bedName,
      ));
    }
    return result;
  }

  void search(String query) {
    final filtered = _applySearch(state.tenants, query);
    final filteredVMs = _applyViewModelSearch(state.viewModels, query);
    emit(state.copyWith(
      searchQuery: query,
      filteredTenants: filtered,
      filteredViewModels: filteredVMs,
    ));
  }

  void setSearchActive(bool active) {
    emit(state.copyWith(
      isSearchActive: active,
      searchQuery: active ? state.searchQuery : '',
      filteredTenants: active ? state.filteredTenants : state.tenants,
      filteredViewModels: active ? state.filteredViewModels : state.viewModels,
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

  List<TenantViewModel> _applyViewModelSearch(
      List<TenantViewModel> models, String query) {
    final trimmedQuery = query.trim().toLowerCase();
    if (trimmedQuery.isEmpty) return models;

    return models.where((vm) {
      final t = vm.tenant;
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
      final registrationContext =
          await _tenantManagementRepository.assignTenant(tenant);
      await _loadTenants(registrationContext: registrationContext);
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

  Future<void> deleteTenant(int tenantId, {int? bedId}) async {
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

  Future<void> transferTenant(
    int tenantId, {
    required int oldBedId,
    required int newBedId,
  }) async {
    emit(state.copyWith(status: TenantOperationStatus.transferring));
    try {
      await _tenantManagementRepository.transferTenant(
        tenantId,
        oldBedId: oldBedId,
        newBedId: newBedId,
      );
      await loadTenants();
    } catch (e) {
      emit(state.copyWith(
        status: TenantOperationStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
