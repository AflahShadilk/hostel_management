import '../entities/tenant_history_detail.dart';
import '../entities/tenant_history_summary.dart';

abstract interface class TenantHistoryRepository {
  /// Fetches a summary list of all completed stays (checked_out status).
  Future<List<TenantHistorySummary>> getCompletedStays();

  /// Fetches the complete details for a specific stay.
  Future<TenantHistoryDetail> getStayDetail(int stayId);
}
