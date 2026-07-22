part of 'tenant_history_detail_cubit.dart';

class TenantHistoryDetailState extends Equatable {
  final bool isLoading;
  final String? error;
  final TenantHistoryDetail? detail;

  const TenantHistoryDetailState({
    this.isLoading = false,
    this.error,
    this.detail,
  });

  TenantHistoryDetailState copyWith({
    bool? isLoading,
    String? error,
    TenantHistoryDetail? detail,
  }) {
    return TenantHistoryDetailState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      detail: detail ?? this.detail,
    );
  }

  @override
  List<Object?> get props => [isLoading, error, detail];
}
