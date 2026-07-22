import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/tenant_history_summary.dart';
import '../../domain/repositories/tenant_history_repository.dart';

part 'tenant_history_state.dart';

enum HistoryFilter { all, thisMonth, lastMonth, currentYear }
enum HistorySort { newestCheckout, oldestCheckout, tenantName }

class TenantHistoryCubit extends Cubit<TenantHistoryState> {
  final TenantHistoryRepository _repository;
  
  List<TenantHistorySummary> _allStays = [];

  TenantHistoryCubit(this._repository) : super(const TenantHistoryState());

  Future<void> loadHistory() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      _allStays = await _repository.getCompletedStays();
      _applyFiltersAndSort();
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
    _applyFiltersAndSort();
  }
  
  void setSearchActive(bool active) {
    emit(state.copyWith(isSearchActive: active));
    if (!active && state.searchQuery.isNotEmpty) {
      setSearchQuery('');
    }
  }

  void setFilter(HistoryFilter filter) {
    emit(state.copyWith(filter: filter));
    _applyFiltersAndSort();
  }

  void setSort(HistorySort sort) {
    emit(state.copyWith(sort: sort));
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    var filtered = List<TenantHistorySummary>.from(_allStays);

    // Apply Search
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((stay) {
        return stay.tenantName.toLowerCase().contains(query) ||
            stay.phoneNumber.contains(query) ||
            stay.tenantId.toString() == query ||
            stay.roomId.toString() == query; // simple room search
      }).toList();
    }

    // Apply Filter
    final now = DateTime.now();
    switch (state.filter) {
      case HistoryFilter.thisMonth:
        filtered = filtered.where((stay) => 
          stay.checkOutDate.year == now.year && stay.checkOutDate.month == now.month
        ).toList();
        break;
      case HistoryFilter.lastMonth:
        final lastMonthDate = DateTime(now.year, now.month - 1);
        filtered = filtered.where((stay) => 
          stay.checkOutDate.year == lastMonthDate.year && stay.checkOutDate.month == lastMonthDate.month
        ).toList();
        break;
      case HistoryFilter.currentYear:
        filtered = filtered.where((stay) => stay.checkOutDate.year == now.year).toList();
        break;
      case HistoryFilter.all:
        break;
    }

    // Apply Sort
    switch (state.sort) {
      case HistorySort.newestCheckout:
        filtered.sort((a, b) => b.checkOutDate.compareTo(a.checkOutDate));
        break;
      case HistorySort.oldestCheckout:
        filtered.sort((a, b) => a.checkOutDate.compareTo(b.checkOutDate));
        break;
      case HistorySort.tenantName:
        filtered.sort((a, b) => a.tenantName.toLowerCase().compareTo(b.tenantName.toLowerCase()));
        break;
    }

    emit(state.copyWith(isLoading: false, stays: filtered));
  }
}
