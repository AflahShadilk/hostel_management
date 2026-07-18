import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/dashboard_repository.dart';
import 'dashboard_state.dart';
import 'dashboard_operation_status.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepository _repository;

  DashboardCubit(this._repository) : super(const DashboardState());

  Future<void> loadDashboard(int hostelId) async {
    if (hostelId <= 0) {
      emit(state.copyWith(
        status: DashboardOperationStatus.failure,
        errorMessage: () => 'Unable to load dashboard.',
      ));
      return;
    }

    if (state.status == DashboardOperationStatus.loading ||
        state.status == DashboardOperationStatus.refreshing) {
      return;
    }

    emit(state.copyWith(
      status: DashboardOperationStatus.loading,
      errorMessage: () => null,
    ));

    try {
      final summary = await _repository.getSummary(hostelId);
      emit(state.copyWith(
        status: DashboardOperationStatus.loaded,
        summary: summary,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: DashboardOperationStatus.failure,
        errorMessage: () => 'Unable to load dashboard.',
      ));
    }
  }

  Future<void> refreshDashboard(int hostelId) async {
    if (hostelId <= 0) {
      emit(state.copyWith(
        status: DashboardOperationStatus.failure,
        errorMessage: () => 'Unable to refresh dashboard.',
      ));
      return;
    }

    if (state.status == DashboardOperationStatus.loading ||
        state.status == DashboardOperationStatus.refreshing) {
      return;
    }

    emit(state.copyWith(
      status: state.summary != null
          ? DashboardOperationStatus.refreshing
          : DashboardOperationStatus.loading,
      errorMessage: () => null,
    ));

    try {
      final summary = await _repository.getSummary(hostelId);
      emit(state.copyWith(
        status: DashboardOperationStatus.loaded,
        summary: summary,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: DashboardOperationStatus.failure,
        errorMessage: () => 'Unable to refresh dashboard.',
      ));
    }
  }
}
