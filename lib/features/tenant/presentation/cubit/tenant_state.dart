import 'package:equatable/equatable.dart';
import '../../domain/entities/tenant_entity.dart';

enum TenantOperationStatus {
  initial,
  loading,
  loaded,
  creating,
  updating,
  deleting,
  checkingOut,
  failure,
}

class TenantState extends Equatable {
  final TenantOperationStatus status;
  final List<TenantEntity> tenants;
  final List<TenantEntity> filteredTenants;
  final String? errorMessage;
  final String searchQuery;

  const TenantState({
    this.status = TenantOperationStatus.initial,
    this.tenants = const [],
    this.filteredTenants = const [],
    this.errorMessage,
    this.searchQuery = '',
  });

  TenantState copyWith({
    TenantOperationStatus? status,
    List<TenantEntity>? tenants,
    List<TenantEntity>? filteredTenants,
    String? errorMessage,
    String? searchQuery,
  }) {
    return TenantState(
      status: status ?? this.status,
      tenants: tenants ?? this.tenants,
      filteredTenants: filteredTenants ?? this.filteredTenants,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props =>
      [status, tenants, filteredTenants, errorMessage, searchQuery];
}
