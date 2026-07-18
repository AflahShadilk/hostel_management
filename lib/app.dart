import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/hostel/presentation/cubit/hostel_cubit.dart';

class HostelManagementApp extends StatelessWidget {
  const HostelManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (_) => getIt<AuthCubit>()),
        // HostelCubit is provided at app-level (factory in GetIt) so the same
        // instance survives across Splash, Login, PinSetup, and HostelSetup
        // without being converted to a singleton.
        BlocProvider<HostelCubit>(create: (_) => getIt<HostelCubit>()),
      ],
      child: MaterialApp.router(
        title: 'Hostel Management',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
