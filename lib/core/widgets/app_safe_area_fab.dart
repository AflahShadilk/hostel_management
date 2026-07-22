import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';

/// Positions a page action above the floating mobile navigation bar.
class AppSafeAreaFab extends StatelessWidget {
  const AppSafeAreaFab({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isMobileNavigation = MediaQuery.sizeOf(context).width < 600;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: isMobileNavigation
              ? kBottomNavigationBarHeight + AppSpacing.md
              : 0,
        ),
        child: child,
      ),
    );
  }
}
