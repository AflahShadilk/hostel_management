import 'package:equatable/equatable.dart';

import '../../../domain/entities/rent_collection_item_entity.dart';

abstract class RentCollectionState extends Equatable {
  const RentCollectionState();

  @override
  List<Object?> get props => [];
}

class RentCollectionInitial extends RentCollectionState {}

class RentCollectionLoading extends RentCollectionState {}

class RentCollectionLoaded extends RentCollectionState {
  final List<RentCollectionItemEntity> items;
  final List<RentCollectionItemEntity> filteredItems;

  // Summaries
  final double totalPendingAmount;
  final double totalOverdueAmount;
  final double totalCollectedThisMonth;
  final int pendingRecordsCount;

  // Active Filters
  final String activeFilter; // 'all', 'pending', 'partial', 'paid', 'overdue'
  final String searchQuery;
  final String activeSort; // 'dueDate', 'tenantName', 'outstanding'

  const RentCollectionLoaded({
    required this.items,
    required this.filteredItems,
    required this.totalPendingAmount,
    required this.totalOverdueAmount,
    required this.totalCollectedThisMonth,
    required this.pendingRecordsCount,
    required this.activeFilter,
    required this.searchQuery,
    required this.activeSort,
  });

  RentCollectionLoaded copyWith({
    List<RentCollectionItemEntity>? items,
    List<RentCollectionItemEntity>? filteredItems,
    double? totalPendingAmount,
    double? totalOverdueAmount,
    double? totalCollectedThisMonth,
    int? pendingRecordsCount,
    String? activeFilter,
    String? searchQuery,
    String? activeSort,
  }) {
    return RentCollectionLoaded(
      items: items ?? this.items,
      filteredItems: filteredItems ?? this.filteredItems,
      totalPendingAmount: totalPendingAmount ?? this.totalPendingAmount,
      totalOverdueAmount: totalOverdueAmount ?? this.totalOverdueAmount,
      totalCollectedThisMonth: totalCollectedThisMonth ?? this.totalCollectedThisMonth,
      pendingRecordsCount: pendingRecordsCount ?? this.pendingRecordsCount,
      activeFilter: activeFilter ?? this.activeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      activeSort: activeSort ?? this.activeSort,
    );
  }

  @override
  List<Object?> get props => [
        items,
        filteredItems,
        totalPendingAmount,
        totalOverdueAmount,
        totalCollectedThisMonth,
        pendingRecordsCount,
        activeFilter,
        searchQuery,
        activeSort,
      ];
}

class RentCollectionError extends RentCollectionState {
  final String message;

  const RentCollectionError(this.message);

  @override
  List<Object?> get props => [message];
}
