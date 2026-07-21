// ignore_for_file: override_on_non_overriding_member

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_management/core/theme/app_theme.dart';
import 'package:hostel_management/core/widgets/app_empty_state.dart';
import 'package:hostel_management/core/widgets/app_loading_indicator.dart';
import 'package:hostel_management/features/auth/domain/entities/user_entity.dart';
import 'package:hostel_management/features/auth/domain/entities/user_role.dart';
import 'package:hostel_management/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:hostel_management/features/auth/presentation/cubit/auth_state.dart';
import 'package:hostel_management/features/dashboard/domain/entities/dashboard_summary_entity.dart';
import 'package:hostel_management/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:hostel_management/features/dashboard/presentation/cubit/dashboard_operation_status.dart';
import 'package:hostel_management/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:hostel_management/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:hostel_management/features/dashboard/presentation/widgets/dashboard_metric_card.dart';
import 'package:hostel_management/features/hostel/domain/entities/hostel_entity.dart';
import 'package:hostel_management/features/hostel/presentation/cubit/hostel_cubit.dart';
import 'package:hostel_management/features/hostel/presentation/cubit/hostel_state.dart';
import 'package:hostel_management/features/hostel/presentation/cubit/hostel_status.dart';

import 'package:hostel_management/features/tenant/presentation/cubit/tenant_cubit.dart';
import 'package:hostel_management/features/tenant/presentation/cubit/tenant_state.dart';

class FakeAuthCubit extends Cubit<AuthState> implements AuthCubit {
  FakeAuthCubit(super.initialState);

  @override
  Future<void> loginWithPassword(
      {required String email,
      required String password,
      required UserRole role}) async {}

  @override
  Future<void> loginWithPin(
      {required String email,
      required String pin,
      required UserRole role}) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> checkAuthStatus() async {}

  @override
  Future<void> checkSession() async {}

  @override
  Future<void> registerOwner(
      {required String name,
      required String phone,
      required String email,
      required String password}) async {}

  @override
  Future<void> setupPin(String pin) async {}

  @override
  Future<void> selectRole(UserRole role) async {}

  @override
  Future<void> unlockWithPin(String pin) async {}

  @override
  Future<void> forgotPin() async {}
}

class FakeHostelCubit extends Cubit<HostelState> implements HostelCubit {
  FakeHostelCubit(super.initialState);

  @override
  Future<void> checkHostelSetup(int ownerUserId) async {}

  @override
  Future<void> createHostel({
    required String name,
    String? logoPath,
    required String address,
    required String phone,
    required String email,
    required String ownerName,
    required int ownerUserId,
  }) async {}

  @override
  Future<void> updateHostel({
    required HostelEntity hostel,
    required String name,
    String? logoPath,
    required String address,
    required String phone,
    required String email,
    required String ownerName,
  }) async {}
}

class FakeDashboardCubit extends Cubit<DashboardState>
    implements DashboardCubit {
  int loadCalls = 0;
  int refreshCalls = 0;

  FakeDashboardCubit(super.initialState);

  @override
  Future<void> loadDashboard(int hostelId) async {
    loadCalls++;
  }

  @override
  Future<void> refreshDashboard(int hostelId) async {
    refreshCalls++;
  }
}

class FakeTenantCubit extends Cubit<TenantState> implements TenantCubit {
  FakeTenantCubit(super.initialState);
  
  @override
  void search(String query) {}
  @override
  void setSearchActive(bool active) {}
  @override
  Future<void> loadTenants() async {}
  @override
  Future<void> createTenant(tenant) async {}
  @override
  Future<void> updateTenant(tenant) async {}
  @override
  Future<void> deleteTenant(int id, {int? bedId}) async {}
  @override
  Future<void> checkOutTenant(int id, {required int bedId}) async {}
  @override
  Future<void> transferTenant(int id, {required int oldBedId, required int newBedId}) async {}
}

Widget _buildTestApp({
  required Widget child,
  required FakeAuthCubit authCubit,
  required FakeHostelCubit hostelCubit,
  required FakeDashboardCubit dashboardCubit,
  required FakeTenantCubit tenantCubit,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<AuthCubit>.value(value: authCubit),
      BlocProvider<HostelCubit>.value(value: hostelCubit),
      BlocProvider<DashboardCubit>.value(value: dashboardCubit),
      BlocProvider<TenantCubit>.value(value: tenantCubit),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: child,
    ),
  );
}

void main() {
  group('DashboardPage UI', () {
    final now = DateTime.now();
    final testHostel = HostelEntity(
      id: 1,
      name: 'Test Hostel',
      address: 'Test Address',
      phone: '123',
      email: 'test@hostel.com',
      ownerName: 'Owner',
      ownerUserId: 1,
      createdAt: now,
      updatedAt: now,
    );

    final testSummary = const DashboardSummaryEntity(
      totalRooms: 10,
      vacantRooms: 5,
      partiallyOccupiedRooms: 2,
      occupiedRooms: 3,
      inactiveRooms: 0,
      totalBeds: 20,
      vacantBeds: 10,
      occupiedBeds: 10,
      inactiveBeds: 0,
      totalTenants: 10,
      activeTenants: 8,
      checkedOutTenants: 2,
      pendingRent: 0.0,
      todayCheckouts: 0,
      recentActivities: [],
    );

    testWidgets('Dashboard loads using valid Hostel ID', (tester) async {
      final authCubit =
          FakeAuthCubit(const AuthState(status: AuthStatus.authenticated));
      final hostelCubit = FakeHostelCubit(
          HostelState(status: HostelStatus.configured, hostel: testHostel));
      final dashboardCubit = FakeDashboardCubit(const DashboardState());
      final tenantCubit = FakeTenantCubit(const TenantState());

      await tester.pumpWidget(_buildTestApp(
        child: const DashboardPage(),
        authCubit: authCubit,
        hostelCubit: hostelCubit,
        dashboardCubit: dashboardCubit,
        tenantCubit: tenantCubit,
      ));

      await tester.pump();

      expect(dashboardCubit.loadCalls, 1);
    });

    testWidgets('Initial loading shows AppLoadingIndicator', (tester) async {
      final authCubit =
          FakeAuthCubit(const AuthState(status: AuthStatus.authenticated));
      final hostelCubit = FakeHostelCubit(
          HostelState(status: HostelStatus.configured, hostel: testHostel));
      final dashboardCubit = FakeDashboardCubit(
          const DashboardState(status: DashboardOperationStatus.loading));
      final tenantCubit = FakeTenantCubit(const TenantState());

      await tester.pumpWidget(_buildTestApp(
        child: const DashboardPage(),
        authCubit: authCubit,
        hostelCubit: hostelCubit,
        dashboardCubit: dashboardCubit,
        tenantCubit: tenantCubit,
      ));

      expect(find.byType(AppLoadingIndicator), findsOneWidget);
    });

    testWidgets('Loaded Dashboard shows Room and Bed metrics', (tester) async {
      final authCubit =
          FakeAuthCubit(const AuthState(status: AuthStatus.authenticated));
      final hostelCubit = FakeHostelCubit(
          HostelState(status: HostelStatus.configured, hostel: testHostel));
      final dashboardCubit = FakeDashboardCubit(DashboardState(
        status: DashboardOperationStatus.loaded,
        summary: testSummary,
      ));
      final tenantCubit = FakeTenantCubit(const TenantState());

      await tester.pumpWidget(_buildTestApp(
        child: const DashboardPage(),
        authCubit: authCubit,
        hostelCubit: hostelCubit,
        dashboardCubit: dashboardCubit,
        tenantCubit: tenantCubit,
      ));

      await tester.pumpAndSettle();

      // Verify metric cards are rendered (data flows from summary → UI)
      expect(find.byType(DashboardMetricCard, skipOffstage: false), findsWidgets);
    });

    testWidgets('Manager without resolved Hostel shows fallback',
        (tester) async {
      final managerUser = UserEntity(
          id: 2,
          name: 'Mgr',
          phone: '123',
          email: 'mgr@test.com',
          role: UserRole.manager,
          createdAt: now);
      final authCubit = FakeAuthCubit(
          AuthState(status: AuthStatus.authenticated, user: managerUser));
      final hostelCubit = FakeHostelCubit(
          const HostelState(status: HostelStatus.notConfigured));
      final dashboardCubit = FakeDashboardCubit(const DashboardState());
      final tenantCubit = FakeTenantCubit(const TenantState());

      await tester.pumpWidget(_buildTestApp(
        child: const DashboardPage(),
        authCubit: authCubit,
        hostelCubit: hostelCubit,
        dashboardCubit: dashboardCubit,
        tenantCubit: tenantCubit,
      ));

      await tester.pumpAndSettle();

      // Should not query dashboard
      expect(dashboardCubit.loadCalls, 0);

      // Should show fallback empty state
      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('Access Pending'), findsOneWidget);
    });
  });
}
