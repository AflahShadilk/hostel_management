import '../entities/dashboard_summary_entity.dart';

abstract interface class DashboardRepository {
  Future<DashboardSummaryEntity> getSummary(int hostelId);
}
