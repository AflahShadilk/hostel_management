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
  Future<UserEntity> createUser(UserEntity user) async => user;
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
    expect(find.text('Owner Login — Coming next'), findsOneWidget);

    // Go back
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Tap Owner Sign Up
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    expect(find.text('Owner Sign Up — Coming next'), findsOneWidget);
  });
}
