import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_management/core/router/app_router.dart';
import 'package:hostel_management/core/router/app_routes.dart';
import 'package:hostel_management/core/theme/app_theme.dart';
import 'package:hostel_management/features/auth/domain/entities/user_entity.dart';
import 'package:hostel_management/features/auth/domain/entities/user_role.dart';
import 'package:hostel_management/features/auth/domain/repositories/auth_repository.dart';
import 'package:hostel_management/features/auth/domain/services/auth_security_service.dart';
import 'package:hostel_management/features/auth/domain/services/auth_session_service.dart';
import 'package:hostel_management/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:hostel_management/features/hostel/domain/entities/hostel_entity.dart';
import 'package:hostel_management/features/hostel/domain/repositories/hostel_repository.dart';
import 'package:hostel_management/features/hostel/presentation/cubit/hostel_cubit.dart';
import 'package:hostel_management/features/hostel/presentation/pages/hostel_setup_page.dart';
import 'package:hostel_management/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:hostel_management/features/dashboard/domain/entities/dashboard_summary_entity.dart';
import 'package:hostel_management/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:hostel_management/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:hostel_management/features/room/domain/entities/room_entity.dart';
import 'package:hostel_management/features/room/domain/entities/room_type.dart';
import 'package:hostel_management/features/room/presentation/cubit/room_cubit.dart';
import 'package:hostel_management/features/room/presentation/cubit/room_state.dart';
import 'package:hostel_management/features/tenant/domain/entities/tenant_entity.dart';
import 'package:hostel_management/features/tenant/presentation/cubit/tenant_cubit.dart';
import 'package:hostel_management/features/tenant/presentation/cubit/tenant_state.dart';
import 'package:get_it/get_it.dart';

// Fake implementations to prevent hitting real database
class FakeAuthRepository implements AuthRepository {
  @override
  Future<UserEntity> createUser(UserEntity user) async => UserEntity(
        id: 1, // Provide a non-null ID to avoid Null check operator error in AuthCubit
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        isActive: user.isActive,
        createdAt: DateTime.now(),
      );
  @override
  Future<void> deleteUser(int id) async {}
  @override
  Future<bool> emailExists(String email) async => false;
  @override
  Future<UserEntity?> getUserByEmail(String email) async {
    if (email == 'manager@example.com') {
      return UserEntity(
        id: 2,
        name: 'Manager',
        email: email,
        phone: '0987654321',
        role: UserRole.manager,
        isActive: true,
        createdAt: DateTime.now(),
      );
    }
    return null;
  }

  @override
  Future<UserEntity?> getUserById(int id) async => null;
  @override
  Future<List<UserEntity>> getUsersByRole(UserRole role) async => [];
  @override
  Future<bool> phoneExists(String phone) async => false;
}

class FakeAuthSecurityService implements AuthSecurityService {
  @override
  Future<void> deleteCredentials({required int userId}) async {}
  @override
  Future<void> savePassword(
      {required int userId, required String password}) async {}
  @override
  Future<void> savePin({required int userId, required String pin}) async {}
  @override
  Future<bool> verifyPassword(
          {required int userId, required String password}) async =>
      true;
  @override
  Future<bool> verifyPin({required int userId, required String pin}) async =>
      true;
}

class FakeAuthSessionService implements AuthSessionService {
  @override
  Future<void> clearSession() async {}
  @override
  Future<int?> getUserId() async =>
      null; // Returns null so we go to unauthenticated -> role selection
  @override
  Future<bool> hasSession() async => false;
  @override
  Future<void> saveSession(int userId) async {}
}

class FakeHostelRepository implements HostelRepository {
  @override
  Future<HostelEntity> createHostel(HostelEntity hostel) async => HostelEntity(
        id: 1,
        name: hostel.name,
        logoPath: hostel.logoPath,
        address: hostel.address,
        phone: hostel.phone,
        email: hostel.email,
        ownerName: hostel.ownerName,
        ownerUserId: hostel.ownerUserId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  @override
  Future<HostelEntity?> getHostelById(int id) async => null;
  @override
  Future<HostelEntity?> getHostelByOwnerUserId(int ownerUserId) async =>
      null; // Simulate no hostel configured yet
  @override
  Future<bool> hasHostelForOwner(int ownerUserId) async => false;
  @override
  Future<HostelEntity> updateHostel(HostelEntity hostel) async => hostel;
}

class FakeDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardSummaryEntity> getSummary(int hostelId) async {
    return const DashboardSummaryEntity(
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
  }
}

class FakeTenantCubit extends Cubit<TenantState> implements TenantCubit {
  FakeTenantCubit(super.initialState);
  @override void search(String query) {}
  @override void setSearchActive(bool active) {}
  @override Future<void> loadTenants() async {}
  @override Future<void> createTenant(TenantEntity tenant) async {}
  @override Future<void> updateTenant(TenantEntity tenant) async {}
  @override Future<void> deleteTenant(int tenantId, {int? bedId}) async {}
  @override Future<void> checkOutTenant(int tenantId, {required int bedId}) async {}
  @override Future<void> transferTenant(int tenantId, {required int oldBedId, required int newBedId}) async {}
}

class FakeRoomCubit extends Cubit<RoomState> implements RoomCubit {
  FakeRoomCubit(super.initialState);
  @override Future<void> loadRooms(int hostelId) async {}
  @override Future<void> createRoom({required int hostelId, required String roomNumber, required String floor, required RoomType roomType, required int numberOfBeds, required double monthlyRent}) async {}
  @override Future<void> updateRoom({required RoomEntity currentRoom, required String roomNumber, required String floor, required RoomType roomType, required int numberOfBeds, required double monthlyRent}) async {}
  @override Future<void> deleteRoom(RoomEntity room) async {}
}

void main() {
  setUpAll(() {
    GetIt.I.registerFactory<DashboardCubit>(
        () => DashboardCubit(FakeDashboardRepository()));
    GetIt.I.registerFactory<TenantCubit>(
        () => FakeTenantCubit(const TenantState()));
    GetIt.I.registerFactory<RoomCubit>(
        () => FakeRoomCubit(const RoomState()));
  });

  testWidgets(
      'App renders Splash and navigates through Sign Up, PIN, and Hostel Setup',
      (WidgetTester tester) async {
    final authCubit = AuthCubit(
      FakeAuthRepository(),
      FakeAuthSecurityService(),
      FakeAuthSessionService(),
    );

    final hostelCubit = HostelCubit(FakeHostelRepository());

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: authCubit),
          BlocProvider<HostelCubit>.value(value: hostelCubit),
        ],
        child: MaterialApp.router(
          title: 'Hostel Management',
          theme: AppTheme.lightTheme,
          routerConfig: AppRouter.router,
        ),
      ),
    );

    // Initial state: should show Splash text
    expect(find.text('Hostel Management'), findsOneWidget);
    expect(find.text('Manage smarter. Stay organized.'), findsOneWidget);

    // Let the initial frame happen so checkAuthStatus() runs
    await tester.pumpAndSettle();

    // Now it should have navigated to Role Selection
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text("Choose how you'd like to continue"), findsOneWidget);
    expect(find.text('Owner'), findsWidgets);
    expect(find.text('Manager'), findsWidgets);

    // Tap Owner Login
    await tester.tap(find.text('Login').first);
    await tester.pumpAndSettle();

    // We should be on Owner Login Page
    expect(find.text('Owner Login'), findsOneWidget);
    expect(find.text('Welcome back, Owner'), findsOneWidget);
    expect(find.text('Sign in to manage your hostel.'), findsOneWidget);
    expect(find.text('Don\'t have an account?'),
        findsOneWidget); // Owner has sign up option
    expect(find.text('Sign Up'), findsWidgets);
    expect(find.text('Password'), findsWidgets); // Password mode is default

    // Switch to PIN mode
    await tester.tap(find.text('PIN').last);
    await tester.pumpAndSettle();
    expect(find.text('4-digit PIN'), findsOneWidget);

    // Switch back to Password mode
    await tester.tap(find.text('Password').last);
    await tester.pumpAndSettle();

    // Go back
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    // Tap Manager Login
    await tester.tap(find.text('Login').last);
    await tester.pumpAndSettle();

    // We should be on Manager Login Page
    expect(find.text('Manager Login'), findsOneWidget);
    expect(find.text('Welcome back, Manager'), findsOneWidget);
    expect(find.text('Sign in to continue managing hostel operations.'),
        findsOneWidget);
    expect(find.text('Don\'t have an account?'),
        findsNothing); // Manager does NOT have sign up option

    // Go back
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    // Tap Owner Sign Up (last element as login is first)
    await tester.tap(find.text('Sign Up').last);
    await tester.pumpAndSettle();

    // We should be on Owner Sign Up Page
    expect(find.text('Create Owner Account'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Phone Number'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);

    // Test Validation (Empty Form)
    final createAccountFinder = find.text('Create Account');
    await tester.ensureVisible(createAccountFinder);
    await tester.tap(createAccountFinder);
    await tester.pumpAndSettle();
    expect(find.text('Please enter your full name'), findsOneWidget);

    // Enter valid details
    await tester.enterText(find.byType(TextField).at(0), 'John Doe');
    await tester.enterText(find.byType(TextField).at(1), '9876543210');
    await tester.enterText(find.byType(TextField).at(2), 'john@example.com');
    await tester.enterText(find.byType(TextField).at(3), 'Password123');

    // Test password visibility toggles
    final passwordField =
        tester.widget<TextField>(find.byType(TextField).at(3));
    expect(passwordField.obscureText, true);

    await tester.tap(find.byIcon(Icons.visibility_outlined).first);
    await tester.pumpAndSettle();

    final passwordFieldVisible =
        tester.widget<TextField>(find.byType(TextField).at(3));
    expect(passwordFieldVisible.obscureText, false);

    // Mismatched confirm password
    await tester.enterText(find.byType(TextField).at(4), 'Password124');

    final confirmPasswordField =
        tester.widget<TextField>(find.byType(TextField).at(4));
    expect(confirmPasswordField.obscureText, true);

    await tester.tap(find.byIcon(Icons.visibility_outlined).last);
    await tester.pumpAndSettle();

    final confirmPasswordFieldVisible =
        tester.widget<TextField>(find.byType(TextField).at(4));
    expect(confirmPasswordFieldVisible.obscureText, false);

    await tester.ensureVisible(createAccountFinder);
    await tester.tap(createAccountFinder);
    await tester.pumpAndSettle();
    expect(find.text('Passwords do not match'), findsOneWidget);

    // Matching confirm password
    await tester.enterText(find.byType(TextField).at(4), 'Password123');
    await tester.pumpAndSettle();
    await tester.ensureVisible(createAccountFinder);
    await tester.tap(createAccountFinder);

    // We might need to wait for the bloc to emit the new state and GoRouter to push Replacement.
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // We should be on PIN Setup Page
    expect(find.text('Set Up PIN'), findsOneWidget);
    expect(find.text('Create your secure PIN'), findsOneWidget);

    // Check fields
    expect(find.text('Create 4-digit PIN'), findsOneWidget);
    expect(find.text('Confirm PIN'), findsOneWidget);

    final pinField = tester.widget<TextField>(find.byType(TextField).first);
    expect(pinField.obscureText, true);

    // Test visibility toggle
    await tester.tap(find.byIcon(Icons.visibility_outlined).first);
    await tester.pumpAndSettle();

    final pinFieldVisible =
        tester.widget<TextField>(find.byType(TextField).first);
    expect(pinFieldVisible.obscureText, false);

    // Empty form validation
    final setPinButton = find.text('Set PIN & Continue');
    await tester.ensureVisible(setPinButton);
    await tester.tap(setPinButton);
    await tester.pumpAndSettle();
    expect(find.text('Please enter a 4-digit PIN.'), findsOneWidget);

    // Too short validation
    await tester.enterText(find.byType(TextField).first, '123');
    await tester.tap(setPinButton);
    await tester.pumpAndSettle();
    expect(find.text('PIN must contain exactly 4 digits.'), findsOneWidget);

    // Mismatched confirm PIN
    await tester.enterText(find.byType(TextField).first, '1234');
    await tester.enterText(find.byType(TextField).last, '1235');
    await tester.tap(setPinButton);
    await tester.pumpAndSettle();
    expect(find.text('PINs do not match.'), findsOneWidget);

    // Valid setup
    await tester.enterText(find.byType(TextField).last, '1234');
    await tester.tap(setPinButton);

    // Wait for auth cubit to save and GoRouter to push Replacement
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Should navigate to HostelSetupPage because FakeHostelRepository returns null for getHostelByOwnerUserId
    expect(find.byType(HostelSetupPage), findsOneWidget);
    expect(find.text('Set Up Your Hostel'), findsOneWidget);
  });

  testWidgets('Manager Login navigates directly to Home',
      (WidgetTester tester) async {
    // Override fake to simulate manager role on login
    final authCubit = AuthCubit(
      FakeAuthRepository(),
      FakeAuthSecurityService(),
      FakeAuthSessionService(),
    );
    final hostelCubit = HostelCubit(FakeHostelRepository());

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: authCubit),
          BlocProvider<HostelCubit>.value(value: hostelCubit),
        ],
        child: MaterialApp.router(
          title: 'Hostel Management',
          theme: AppTheme.lightTheme,
          routerConfig: AppRouter.router,
        ),
      ),
    );

    // Skip to Manager Login
    AppRouter.router.go(AppRoutes.managerLoginPath);
    await tester.pumpAndSettle();

    expect(find.text('Manager Login'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'manager@example.com');
    await tester.enterText(find.byType(TextField).last, 'password123');
    await tester.tap(find.text('Sign In'));

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Managers go straight to home, bypassing HostelSetup check
    expect(find.byType(DashboardPage), findsOneWidget);
  });
}
