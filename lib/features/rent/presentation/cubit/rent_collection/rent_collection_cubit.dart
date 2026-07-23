// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/constants/rent_status_constants.dart';
import '../../../domain/entities/rent_collection_item_entity.dart';
import '../../../domain/repositories/rent_collection_repository.dart';
import '../../../domain/repositories/rent_repository.dart';
import 'rent_collection_state.dart';

class RentCollectionCubit extends Cubit<RentCollectionState> {
  final RentCollectionRepository _collectionRepo;
  final RentRepository _rentRepo;

  RentCollectionCubit(this._collectionRepo, this._rentRepo)
      : super(RentCollectionInitial());

  Future<void> load() async {
    try {
      emit(RentCollectionLoading());

      // Automatic Billing Check: Ensure all billing periods are up to date
      await _rentRepo.generateNextBillingPeriods();

      final items = await _collectionRepo.getRentCollectionItems();

      _emitLoaded(
        items: items,
        activeFilter: 'all',
        searchQuery: '',
        activeSort: 'dueDate',
      );
    } catch (e) {
      emit(RentCollectionError('Failed to load rent collection: $e'));
    }
  }

  void setFilter(String filter) {
    if (state is RentCollectionLoaded) {
      final currentState = state as RentCollectionLoaded;
      _emitLoaded(
        items: currentState.items,
        activeFilter: filter,
        searchQuery: currentState.searchQuery,
        activeSort: currentState.activeSort,
      );
    }
  }

  void setSearchQuery(String query) {
    if (state is RentCollectionLoaded) {
      final currentState = state as RentCollectionLoaded;
      _emitLoaded(
        items: currentState.items,
        activeFilter: currentState.activeFilter,
        searchQuery: query,
        activeSort: currentState.activeSort,
      );
    }
  }

  void setSort(String sort) {
    if (state is RentCollectionLoaded) {
      final currentState = state as RentCollectionLoaded;
      _emitLoaded(
        items: currentState.items,
        activeFilter: currentState.activeFilter,
        searchQuery: currentState.searchQuery,
        activeSort: sort,
      );
    }
  }

  void _emitLoaded({
    required List<RentCollectionItemEntity> items,
    required String activeFilter,
    required String searchQuery,
    required String activeSort,
  }) {
    // 1. Calculate Summaries based on ALL active items (before filters)
    double totalPending = 0;
    double totalOverdue = 0;
    double totalCollectedThisMonth = 0;
    int pendingCount = 0;

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    for (final item in items) {
      final r = item.rentRecord;
      if (r.status == RentStatus.pending ||
          r.status == RentStatus.partial ||
          r.status == RentStatus.overdue) {
        totalPending += r.outstanding;
        pendingCount++;
      }
      if (r.status == RentStatus.overdue) {
        totalOverdue += r.outstanding;
      }

      // Assuming 'generatedAt' or 'createdAt' within this month represents current billing cycle for simple "Collected This Month"
      // More accurate: we should check payments, but this asks for "Total Collected This Month".
      // Without adding a massive payment fetch, we can sum amountPaid of rent records whose billing period overlaps this month,
      // or simply rent records whose due date falls in this month.
      if (r.dueDate.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
          r.dueDate.isBefore(endOfMonth.add(const Duration(days: 1)))) {
        totalCollectedThisMonth += r.amountPaid;
      }
    }

    // 2. Filter
    var filtered = items.where((item) {
      final r = item.rentRecord;

      // Status filter
      if (activeFilter == 'pending' && r.status != RentStatus.pending)
        return false;
      if (activeFilter == 'partial' && r.status != RentStatus.partial)
        return false;
      if (activeFilter == 'paid' && r.status != RentStatus.paid) return false;
      if (activeFilter == 'overdue' && r.status != RentStatus.overdue)
        return false;

      // Search filter
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final matchesTenant = item.tenantName.toLowerCase().contains(q);
        final matchesRoom = item.roomNumber.toLowerCase().contains(q);
        final matchesBed = item.bedNumber.toLowerCase().contains(q);
        if (!matchesTenant && !matchesRoom && !matchesBed) {
          return false;
        }
      }

      return true;
    }).toList();

    // 3. Sort
    filtered.sort((a, b) {
      switch (activeSort) {
        case 'tenantName':
          return a.tenantName.compareTo(b.tenantName);
        case 'outstanding':
          // descending outstanding
          return b.rentRecord.outstanding.compareTo(a.rentRecord.outstanding);
        case 'dueDate':
        default:
          // ascending due date
          return a.rentRecord.dueDate.compareTo(b.rentRecord.dueDate);
      }
    });

    emit(RentCollectionLoaded(
      items: items,
      filteredItems: filtered,
      totalPendingAmount: totalPending,
      totalOverdueAmount: totalOverdue,
      totalCollectedThisMonth: totalCollectedThisMonth,
      pendingRecordsCount: pendingCount,
      activeFilter: activeFilter,
      searchQuery: searchQuery,
      activeSort: activeSort,
    ));
  }
}
