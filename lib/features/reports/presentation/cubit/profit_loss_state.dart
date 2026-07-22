import 'package:equatable/equatable.dart';

import '../../domain/entities/profit_loss_entity.dart';
import 'reports_date_filter.dart';

class ProfitLossState extends Equatable {
  final ProfitLossEntity? data;
  final bool isLoading;
  final String? error;
  final ReportsDateFilter activeFilter;
  final DateTime? customFrom;
  final DateTime? customTo;

  const ProfitLossState({
    this.data,
    this.isLoading = false,
    this.error,
    this.activeFilter = ReportsDateFilter.thisMonth,
    this.customFrom,
    this.customTo,
  });

  ProfitLossState copyWith({
    ProfitLossEntity? data,
    bool? isLoading,
    String? error,
    ReportsDateFilter? activeFilter,
    DateTime? customFrom,
    DateTime? customTo,
    bool clearError = false,
    bool clearCustomDates = false,
  }) {
    return ProfitLossState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      activeFilter: activeFilter ?? this.activeFilter,
      customFrom: clearCustomDates ? null : (customFrom ?? this.customFrom),
      customTo: clearCustomDates ? null : (customTo ?? this.customTo),
    );
  }

  @override
  List<Object?> get props => [data, isLoading, error, activeFilter, customFrom, customTo];
}
