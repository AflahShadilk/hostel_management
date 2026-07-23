// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/reports_repository.dart';
import 'profit_loss_state.dart';
import 'reports_date_filter.dart';

class ProfitLossCubit extends Cubit<ProfitLossState> {
  final ReportsRepository _reportsRepository;

  ProfitLossCubit(this._reportsRepository) : super(const ProfitLossState());

  /// Load data for a preset filter.
  Future<void> loadWithFilter(ReportsDateFilter filter) async {
    if (filter == ReportsDateFilter.custom)
      return; // caller must use [loadWithCustomRange]
    emit(state.copyWith(
        isLoading: true,
        clearError: true,
        activeFilter: filter,
        clearCustomDates: true));
    try {
      final now = DateTime.now();
      final (from, to) = filter.resolve(now);
      final data = await _reportsRepository.getProfitLoss(from: from, to: to);
      emit(state.copyWith(isLoading: false, data: data));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  /// Load data for a custom date range.
  Future<void> loadWithCustomRange(DateTime from, DateTime to) async {
    emit(state.copyWith(
      isLoading: true,
      clearError: true,
      activeFilter: ReportsDateFilter.custom,
      customFrom: from,
      customTo: to,
    ));
    try {
      final data = await _reportsRepository.getProfitLoss(from: from, to: to);
      emit(state.copyWith(isLoading: false, data: data));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> refresh() async {
    if (state.activeFilter == ReportsDateFilter.custom &&
        state.customFrom != null &&
        state.customTo != null) {
      await loadWithCustomRange(state.customFrom!, state.customTo!);
    } else {
      await loadWithFilter(state.activeFilter);
    }
  }
}
