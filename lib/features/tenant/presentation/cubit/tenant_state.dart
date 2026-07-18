import 'package:equatable/equatable.dart';
import '../../domain/entities/tenant_entity.dart';
import '../models/tenant_view_model.dart';

enum TenantOperationStatus {
  initial,
  loading,
  loaded,
  creating,
  updating,
  deleting,
  checkingOut,
  transferring,
  failure,
}

class TenantState extends Equatable {
  final TenantOperationStatus status;
  final List<TenantEntity> tenants;
  final List<TenantEntity> filteredTenants;
  final List<TenantViewModel> viewModels;
  final List<TenantViewModel> filteredViewModels;
  final String? errorMessage;
  final String searchQuery;
  final bool isSearchActive;

  const TenantState({
    this.status = TenantOperationStatus.initial,
    this.tenants = const [],
    this.filteredTenants = const [],
    this.viewModels = const [],
    this.filteredViewModels = const [],
    this.errorMessage,
    this.searchQuery = '',
    this.isSearchActive = false,
  });

  TenantState copyWith({
    TenantOperationStatus? status,
    List<TenantEntity>? tenants,
    List<TenantEntity>? filteredTenants,
    List<TenantViewModel>? viewModels,
    List<TenantViewModel>? filteredViewModels,
    String? errorMessage,
    String? searchQuery,
    bool? isSearchActive,
  }) {
    return TenantState(
      status: status ?? this.status,
      tenants: tenants ?? this.tenants,
      filteredTenants: filteredTenants ?? this.filteredTenants,
      viewModels: viewModels ?? this.viewModels,
      filteredViewModels: filteredViewModels ?? this.filteredViewModels,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      isSearchActive: isSearchActive ?? this.isSearchActive,
    );
  }

  @override
  List<Object?> get props => [
        status,
        tenants,
        filteredTenants,
        viewModels,
        filteredViewModels,
        errorMessage,
        searchQuery,
        isSearchActive,
      ];
}
