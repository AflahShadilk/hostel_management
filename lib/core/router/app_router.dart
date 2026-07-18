import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../../core/presentation/main_shell_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'app_routes.dart';

import '../../features/auth/domain/entities/user_role.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/role_selection_page.dart';
import '../../features/auth/presentation/pages/owner_sign_up_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/pin_setup_page.dart';
import '../../features/hostel/presentation/pages/hostel_setup_page.dart';
import '../../features/room/domain/entities/room_entity.dart';
import '../../features/room/presentation/cubit/room_cubit.dart';
import '../../features/room/presentation/pages/room_management_page.dart';
import '../../features/room/presentation/pages/add_room_page.dart';
import '../../features/room/presentation/pages/edit_room_page.dart';
import '../../features/room/presentation/pages/bed_management_page.dart';
import '../../features/room/presentation/cubit/bed_cubit.dart';
import '../../features/tenant/domain/entities/tenant_entity.dart';
import '../../features/tenant/presentation/cubit/tenant_cubit.dart';
import '../../features/tenant/presentation/pages/add_tenant_page.dart';
import '../../features/tenant/presentation/pages/edit_tenant_page.dart';
import '../../features/tenant/presentation/pages/tenant_management_page.dart';
import '../../features/tenant/presentation/pages/transfer_tenant_page.dart';

abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splashPath,
    errorBuilder: (context, state) => const _RouteErrorPage(),
    routes: [
      GoRoute(
        name: AppRoutes.splashName,
        path: AppRoutes.splashPath,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        name: AppRoutes.roleSelectionName,
        path: AppRoutes.roleSelectionPath,
        builder: (context, state) => const RoleSelectionPage(),
      ),
      GoRoute(
        path: AppRoutes.ownerLoginPath,
        name: AppRoutes.ownerLoginName,
        builder: (context, state) => const LoginPage(role: UserRole.owner),
      ),
      GoRoute(
        path: AppRoutes.managerLoginPath,
        name: AppRoutes.managerLoginName,
        builder: (context, state) => const LoginPage(role: UserRole.manager),
      ),
      GoRoute(
        name: AppRoutes.ownerSignUpName,
        path: AppRoutes.ownerSignUpPath,
        builder: (context, state) => const OwnerSignUpPage(),
      ),
      GoRoute(
        name: AppRoutes.pinSetupName,
        path: AppRoutes.pinSetupPath,
        builder: (context, state) => const PinSetupPage(),
      ),
      GoRoute(
        name: AppRoutes.hostelSetupName,
        path: AppRoutes.hostelSetupPath,
        builder: (context, state) => const HostelSetupPage(),
      ),
      // -----------------------------------------------------------------------
      // Main Application Shell
      // -----------------------------------------------------------------------
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => getIt<DashboardCubit>()),
              BlocProvider(create: (_) => getIt<RoomCubit>()),
              BlocProvider(create: (_) => getIt<TenantCubit>()),
            ],
            child: MainShellPage(navigationShell: navigationShell),
          );
        },
        branches: [
          // Branch 0: Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoutes.homeName,
                path: AppRoutes.homePath,
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          // Branch 1: Room Management
          StatefulShellBranch(
            routes: [
              ShellRoute(
                builder: (context, state, child) {
                  return child;
                },
                routes: [
                  GoRoute(
                    name: AppRoutes.roomManagementName,
                    path: AppRoutes.roomManagementPath,
                    builder: (context, state) => const RoomManagementPage(),
                    routes: [
                      GoRoute(
                        name: AppRoutes.addRoomName,
                        path: AppRoutes.addRoomPath,
                        builder: (context, state) => const AddRoomPage(),
                      ),
                      GoRoute(
                        name: AppRoutes.editRoomName,
                        path: AppRoutes.editRoomPath,
                        builder: (context, state) {
                          final room = state.extra as RoomEntity?;
                          return EditRoomPage(room: room);
                        },
                      ),
                      GoRoute(
                        name: AppRoutes.bedManagementName,
                        path: AppRoutes.bedManagementPath,
                        builder: (context, state) {
                          final roomIdStr = state.pathParameters['roomId'] ?? '';
                          final room = state.extra as RoomEntity?;
                          return BlocProvider(
                            create: (_) => getIt<BedCubit>(),
                            child: BedManagementPage(roomIdStr: roomIdStr, room: room),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Branch 2: Tenant Management
          StatefulShellBranch(
            routes: [
              ShellRoute(
                builder: (context, state, child) {
                  return child;
                },
                routes: [
                  GoRoute(
                    name: AppRoutes.tenantManagementName,
                    path: AppRoutes.tenantManagementPath,
                    builder: (context, state) => const TenantManagementPage(),
                    routes: [
                      GoRoute(
                        name: AppRoutes.addTenantName,
                        path: AppRoutes.addTenantPath,
                        builder: (context, state) => const AddTenantPage(),
                      ),
                      GoRoute(
                        name: AppRoutes.editTenantName,
                        path: AppRoutes.editTenantPath,
                        builder: (context, state) {
                          final tenant = state.extra as TenantEntity?;
                          return EditTenantPage(tenant: tenant);
                        },
                      ),
                      GoRoute(
                        name: AppRoutes.transferTenantName,
                        path: AppRoutes.transferTenantPath,
                        builder: (context, state) {
                          final tenant = state.extra as TenantEntity?;
                          return TransferTenantPage(tenant: tenant);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],

  );
}

class _RouteErrorPage extends StatelessWidget {
  const _RouteErrorPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Page not found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.goNamed(AppRoutes.homeName),
                child: const Text('Go to home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
