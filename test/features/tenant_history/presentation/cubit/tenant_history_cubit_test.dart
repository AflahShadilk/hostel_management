import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_management/features/tenant_history/domain/entities/tenant_history_summary.dart';
import 'package:hostel_management/features/tenant_history/domain/entities/tenant_history_detail.dart';
import 'package:hostel_management/features/tenant_history/domain/repositories/tenant_history_repository.dart';
import 'package:hostel_management/features/tenant_history/presentation/cubit/tenant_history_cubit.dart';

class MockTenantHistoryRepository implements TenantHistoryRepository {
  final List<TenantHistorySummary> mockStays;

  MockTenantHistoryRepository(this.mockStays);

  @override
  Future<List<TenantHistorySummary>> getCompletedStays() async {
    return mockStays;
  }

  @override
  Future<TenantHistoryDetail> getStayDetail(int stayId) async {
    throw UnimplementedError();
  }
}

void main() {
  group('TenantHistoryCubit', () {
    late TenantHistoryCubit cubit;
    late List<TenantHistorySummary> stays;

    setUp(() {
      stays = [
        TenantHistorySummary(
          stayId: 1,
          tenantId: 1,
          tenantName: 'Alice',
          phoneNumber: '1111',
          roomId: 101,
          bedId: 1,
          checkInDate: DateTime(2026, 1, 1),
          checkOutDate: DateTime(2026, 1, 10), // Oldest
          monthlyRentSnapshot: 5000,
          totalRentCharged: 1000,
          totalPaid: 1000,
          depositAmount: 0,
          depositRefunded: 0,
          settlementStatus: 'completed',
        ),
        TenantHistorySummary(
          stayId: 2,
          tenantId: 2,
          tenantName: 'Bob',
          phoneNumber: '2222',
          roomId: 102,
          bedId: 1,
          checkInDate: DateTime(2026, 7, 1),
          checkOutDate: DateTime.now(), // Newest (Assuming now is after Jan)
          monthlyRentSnapshot: 5000,
          totalRentCharged: 1000,
          totalPaid: 1000,
          depositAmount: 0,
          depositRefunded: 0,
          settlementStatus: 'completed',
        ),
      ];

      cubit = TenantHistoryCubit(MockTenantHistoryRepository(stays));
    });

    test('loadHistory fetches stays and applies default sort (newestCheckout)', () async {
      await cubit.loadHistory();

      expect(cubit.state.isLoading, false);
      expect(cubit.state.stays.length, 2);
      expect(cubit.state.stays.first.tenantName, 'Bob'); // Bob checked out later
    });

    test('setSearchQuery filters stays by tenant name', () async {
      await cubit.loadHistory();
      cubit.setSearchQuery('ali');

      expect(cubit.state.stays.length, 1);
      expect(cubit.state.stays.first.tenantName, 'Alice');
    });

    test('setSort(oldestCheckout) sorts appropriately', () async {
      await cubit.loadHistory();
      cubit.setSort(HistorySort.oldestCheckout);

      expect(cubit.state.stays.first.tenantName, 'Alice');
    });
  });
}
