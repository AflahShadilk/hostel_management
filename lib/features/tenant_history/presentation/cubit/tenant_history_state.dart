part of 'tenant_history_cubit.dart';

class TenantHistoryState extends Equatable {
  final bool isLoading;
  final String? error;
  final List<TenantHistorySummary> stays;
  final String searchQuery;
  final bool isSearchActive;
  final HistoryFilter filter;
  final HistorySort sort;

  const TenantHistoryState({
    this.isLoading = false,
    this.error,
    this.stays = const [],
    this.searchQuery = '',
    this.isSearchActive = false,
    this.filter = HistoryFilter.all,
    this.sort = HistorySort.newestCheckout,
  });

  TenantHistoryState copyWith({
    bool? isLoading,
    String? error,
    List<TenantHistorySummary>? stays,
    String? searchQuery,
    bool? isSearchActive,
    HistoryFilter? filter,
    HistorySort? sort,
  }) {
    return TenantHistoryState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      stays: stays ?? this.stays,
      searchQuery: searchQuery ?? this.searchQuery,
      isSearchActive: isSearchActive ?? this.isSearchActive,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        error,
        stays,
        searchQuery,
        isSearchActive,
        filter,
        sort,
      ];
}
