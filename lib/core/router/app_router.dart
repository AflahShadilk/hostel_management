import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/pages/home_page.dart';
import 'app_routes.dart';

import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/role_selection_page.dart';
import '../../features/auth/presentation/pages/owner_sign_up_page.dart';

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
        name: AppRoutes.ownerLoginName,
        path: AppRoutes.ownerLoginPath,
        builder: (context, state) =>
            const _PlaceholderPage(title: 'Owner Login — Coming next'),
      ),
      GoRoute(
        name: AppRoutes.ownerSignUpName,
        path: AppRoutes.ownerSignUpPath,
        builder: (context, state) => const OwnerSignUpPage(),
      ),
      GoRoute(
        name: AppRoutes.pinSetupName,
        path: AppRoutes.pinSetupPath,
        builder: (context, state) =>
            const _PlaceholderPage(title: 'PIN Setup — Coming next'),
      ),
      GoRoute(
        name: AppRoutes.managerLoginName,
        path: AppRoutes.managerLoginPath,
        builder: (context, state) =>
            const _PlaceholderPage(title: 'Manager Login — Coming next'),
      ),
      GoRoute(
        name: AppRoutes.homeName,
        path: AppRoutes.homePath,
        builder: (context, state) => const HomePage(),
      ),
    ],
  );
}

class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Placeholder')),
      body: Center(child: Text(title)),
    );
  }
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
