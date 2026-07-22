import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/tenant_history_detail.dart';
import '../../domain/repositories/tenant_history_repository.dart';

part 'tenant_history_detail_state.dart';

class TenantHistoryDetailCubit extends Cubit<TenantHistoryDetailState> {
  final TenantHistoryRepository _repository;

  TenantHistoryDetailCubit(this._repository)
      : super(const TenantHistoryDetailState());

  Future<void> loadDetail(int stayId) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final detail = await _repository.getStayDetail(stayId);
      emit(state.copyWith(isLoading: false, detail: detail));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
