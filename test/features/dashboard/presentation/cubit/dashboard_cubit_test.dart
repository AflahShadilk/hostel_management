import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_management/features/dashboard/domain/entities/dashboard_summary_entity.dart';
import 'package:hostel_management/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:hostel_management/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:hostel_management/features/dashboard/presentation/cubit/dashboard_operation_status.dart';

class FakeDashboardRepository implements DashboardRepository {
  bool shouldFail = false;
  DashboardSummaryEntity fakeSummary = const DashboardSummaryEntity(
    totalRooms: 10,
    vacantRooms: 5,
    partiallyOccupiedRooms: 0,
    occupiedRooms: 5,
    inactiveRooms: 0,
    totalBeds: 20,
    vacantBeds: 10,
    occupiedBeds: 10,
    inactiveBeds: 0,
    totalTenants: 10,
    activeTenants: 10,
    checkedOutTenants: 0,
  );

  @override
  Future<DashboardSummaryEntity> getSummary(int hostelId) async {
    if (shouldFail) throw Exception('Fake error');
    return fakeSummary;
  }
}

void main() {
  group('DashboardCubit', () {
    late FakeDashboardRepository repository;
    late DashboardCubit cubit;

    setUp(() {
      repository = FakeDashboardRepository();
      cubit = DashboardCubit(repository);
    });

    test('initial state is correct', () {
      expect(cubit.state.status, DashboardOperationStatus.initial);
      expect(cubit.state.summary, isNull);
    });

    test('loadDashboard success', () async {
      await cubit.loadDashboard(1);

      expect(cubit.state.status, DashboardOperationStatus.loaded);
      expect(cubit.state.summary, repository.fakeSummary);
    });

    test('loadDashboard failure', () async {
      repository.shouldFail = true;
      await cubit.loadDashboard(1);

      expect(cubit.state.status, DashboardOperationStatus.failure);
      expect(cubit.state.errorMessage, 'Unable to load dashboard.');
    });

    test('loadDashboard invalid hostelId', () async {
      await cubit.loadDashboard(-1);

      expect(cubit.state.status, DashboardOperationStatus.failure);
      expect(cubit.state.errorMessage, 'Unable to load dashboard.');
    });

    test('refreshDashboard success preserves state then updates', () async {
      await cubit.loadDashboard(1); // load initial

      // mutate fake summary
      repository.fakeSummary = const DashboardSummaryEntity(
        totalRooms: 11,
        vacantRooms: 6,
        partiallyOccupiedRooms: 2,
        occupiedRooms: 2,
        inactiveRooms: 1,
        totalBeds: 22,
        vacantBeds: 12,
        occupiedBeds: 8,
        inactiveBeds: 2,
        totalTenants: 10,
        activeTenants: 10,
        checkedOutTenants: 0,
      );

      // We cannot easily test the 'refreshing' intermediate state with simple await,
      // but we can test the final state.
      await cubit.refreshDashboard(1);

      expect(cubit.state.status, DashboardOperationStatus.loaded);
      expect(cubit.state.summary?.totalRooms, 11);
    });

    test('refreshDashboard failure preserves summary', () async {
      await cubit.loadDashboard(1);
      final initialSummary = cubit.state.summary;

      repository.shouldFail = true;
      await cubit.refreshDashboard(1);

      expect(cubit.state.status, DashboardOperationStatus.failure);
      expect(cubit.state.summary, initialSummary); // preserved
      expect(cubit.state.errorMessage, 'Unable to refresh dashboard.');
    });

    test('zero-data summary is loaded successfully', () async {
      repository.fakeSummary = const DashboardSummaryEntity(
        totalRooms: 10,
        vacantRooms: 3,
        partiallyOccupiedRooms: 2,
        occupiedRooms: 5,
        inactiveRooms: 0,
        totalBeds: 20,
        vacantBeds: 10,
        occupiedBeds: 10,
        inactiveBeds: 0,
        totalTenants: 10,
        activeTenants: 10,
        checkedOutTenants: 0,
      );

      await cubit.loadDashboard(1);

      expect(cubit.state.status, DashboardOperationStatus.loaded);
      expect(cubit.state.summary?.totalRooms, 10);
    });
  });
}
