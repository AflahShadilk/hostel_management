import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../../features/home/presentation/pages/home_page.dart';
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
      GoRoute(
        name: AppRoutes.homeName,
        path: AppRoutes.homePath,
        builder: (context, state) => const HomePage(),
      ),

      // -----------------------------------------------------------------------
      // Room Management — RoomCubit is scoped to this route shell so it
      // persists across Room List → Add Room → Edit Room → Room List transitions.
      // -----------------------------------------------------------------------
      ShellRoute(
        builder: (context, state, child) {
          return BlocProvider<RoomCubit>(
            create: (_) => getIt<RoomCubit>(),
            child: child,
          );
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
