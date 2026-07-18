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
import 'package:hostel_management/features/hostel/domain/entities/hostel_entity.dart';
import 'package:hostel_management/features/hostel/presentation/cubit/hostel_cubit.dart';
import 'package:hostel_management/features/hostel/presentation/cubit/hostel_state.dart';
import 'package:hostel_management/features/hostel/presentation/cubit/hostel_status.dart';

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

Widget _buildTestApp({
  required Widget child,
  required FakeAuthCubit authCubit,
  required FakeHostelCubit hostelCubit,
  required FakeDashboardCubit dashboardCubit,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<AuthCubit>.value(value: authCubit),
      BlocProvider<HostelCubit>.value(value: hostelCubit),
      BlocProvider<DashboardCubit>.value(value: dashboardCubit),
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
      occupiedRooms: 2,
      inactiveRooms: 1,
      totalBeds: 20,
      vacantBeds: 10,
      occupiedBeds: 8,
      inactiveBeds: 2,
    );

    testWidgets('Dashboard loads using valid Hostel ID', (tester) async {
      final authCubit =
          FakeAuthCubit(const AuthState(status: AuthStatus.authenticated));
      final hostelCubit = FakeHostelCubit(
          HostelState(status: HostelStatus.configured, hostel: testHostel));
      final dashboardCubit = FakeDashboardCubit(const DashboardState());

      await tester.pumpWidget(_buildTestApp(
        child: const DashboardPage(),
        authCubit: authCubit,
        hostelCubit: hostelCubit,
        dashboardCubit: dashboardCubit,
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

      await tester.pumpWidget(_buildTestApp(
        child: const DashboardPage(),
        authCubit: authCubit,
        hostelCubit: hostelCubit,
        dashboardCubit: dashboardCubit,
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

      await tester.pumpWidget(_buildTestApp(
        child: const DashboardPage(),
        authCubit: authCubit,
        hostelCubit: hostelCubit,
        dashboardCubit: dashboardCubit,
      ));

      await tester.pumpAndSettle();

      // Check values
      expect(find.text('10'), findsWidgets); // Total Rooms / Vacant beds
      expect(find.text('5'), findsWidgets); // Vacant Rooms
      expect(find.text('20'), findsWidgets); // Total Beds
      expect(find.text('8'), findsWidgets); // Occupied beds

      // Check labels
      expect(find.text('Total Rooms'), findsOneWidget);
      expect(find.text('Total Beds'), findsOneWidget);
      expect(find.text('Partially Occupied'), findsOneWidget);
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

      await tester.pumpWidget(_buildTestApp(
        child: const DashboardPage(),
        authCubit: authCubit,
        hostelCubit: hostelCubit,
        dashboardCubit: dashboardCubit,
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
