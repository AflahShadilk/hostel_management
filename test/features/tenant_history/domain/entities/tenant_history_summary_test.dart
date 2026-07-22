import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_management/features/tenant_history/domain/entities/tenant_history_summary.dart';

void main() {
  group('TenantHistorySummary', () {
    test('totalStayDays calculates correct duration inclusive of check-in and check-out days', () {
      final summary = TenantHistorySummary(
        stayId: 1,
        tenantId: 1,
        tenantName: 'John Doe',
        phoneNumber: '1234567890',
        roomId: 101,
        bedId: 1,
        checkInDate: DateTime(2026, 7, 21),
        checkOutDate: DateTime(2026, 7, 25),
        monthlyRentSnapshot: 5000.0,
        totalRentCharged: 5000.0,
        totalPaid: 5000.0,
        depositAmount: 5000.0,
        depositRefunded: 5000.0,
        settlementStatus: 'completed',
      );

      // 21, 22, 23, 24, 25 = 5 days
      expect(summary.totalStayDays, equals(5));
    });
  });
}
