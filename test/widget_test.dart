import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_management/core/router/app_router.dart';
import 'package:hostel_management/core/theme/app_theme.dart';
import 'package:hostel_management/features/auth/domain/entities/user_entity.dart';
import 'package:hostel_management/features/auth/domain/entities/user_role.dart';
import 'package:hostel_management/features/auth/domain/repositories/auth_repository.dart';
import 'package:hostel_management/features/auth/domain/services/auth_security_service.dart';
import 'package:hostel_management/features/auth/domain/services/auth_session_service.dart';
import 'package:hostel_management/features/auth/presentation/cubit/auth_cubit.dart';

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
  Future<UserEntity?> getUserByEmail(String email) async => null;
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

void main() {
  testWidgets('App renders Splash and navigates to Role Selection',
      (WidgetTester tester) async {
    final authCubit = AuthCubit(
      FakeAuthRepository(),
      FakeAuthSecurityService(),
      FakeAuthSessionService(),
    );

    await tester.pumpWidget(
      BlocProvider<AuthCubit>.value(
        value: authCubit,
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
    await tester.enterText(find.byType(TextField).at(1), '1234567890');
    await tester.enterText(find.byType(TextField).at(2), 'john@example.com');
    await tester.enterText(find.byType(TextField).at(3), 'password123');

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
    await tester.enterText(find.byType(TextField).at(4), 'password124');

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
    await tester.enterText(find.byType(TextField).at(4), 'password123');
    await tester.ensureVisible(createAccountFinder);
    await tester.tap(createAccountFinder);

    // We might need to wait for the bloc to emit the new state and GoRouter to push Replacement.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // The fake auth cubit registers the owner and emits registrationPendingPin,
    // which navigates to PIN setup placeholder.
    expect(find.text('PIN Setup — Coming next'), findsOneWidget);
  });
}
