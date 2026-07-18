import 'package:equatable/equatable.dart';
import '../../domain/entities/dashboard_summary_entity.dart';
import 'dashboard_operation_status.dart';

class DashboardState extends Equatable {
  final DashboardOperationStatus status;
  final DashboardSummaryEntity? summary;
  final String? errorMessage;

  const DashboardState({
    this.status = DashboardOperationStatus.initial,
    this.summary,
    this.errorMessage,
  });

  DashboardState copyWith({
    DashboardOperationStatus? status,
    DashboardSummaryEntity? summary,
    String? Function()? errorMessage,
  }) {
    return DashboardState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, summary, errorMessage];
}
