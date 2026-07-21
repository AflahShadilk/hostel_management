import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:go_router/go_router.dart';
import '../router/app_routes.dart';
import '../theme/app_colors.dart';

class MainShellPage extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellPage({
    super.key,
    required this.navigationShell,
  });

  /// Maps the 12 router branches to the 5 bottom navigation tabs.
  int _getSelectedIndex(int branchIndex) {
    switch (branchIndex) {
      case 1:
        return 0; // Dashboard
      case 2:
        return 1; // Rooms
      case 3:
      case 4:
      case 5:
        return 2; // Tenants (Tenants, Stays, Checkout)
      case 6:
      case 7:
      case 8:
      case 9:
      case 10:
      case 11:
        return 3; // Finance (Damage, Deposits, Receipts, Payments, Rent, Expenses)
      case 0:
      default:
        return 4; // More (Search, etc.)
    }
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        // Dashboard
        _goBranch(1);
        break;
      case 1:
        // Rooms
        _goBranch(2);
        break;
      case 2:
        // Tenants Menu
        _showTenantsMenu(context);
        break;
      case 3:
        // Finance Menu
        _showFinanceMenu(context);
        break;
      case 4:
        // More Menu
        _showMoreMenu(context);
        break;
    }
  }

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  void _showTenantsMenu(BuildContext context) {
    _showMenuSheet(
      context,
      title: 'Tenants & Stays',
      items: [
        _MenuItem(
          icon: Icons.groups_rounded,
          label: 'Tenants',
          onTap: () {
            Navigator.pop(context);
            _goBranch(3);
          },
        ),
        _MenuItem(
          icon: Icons.hotel_rounded,
          label: 'Stay History',
          onTap: () {
            Navigator.pop(context);
            _goBranch(4);
          },
        ),
        _MenuItem(
          icon: Icons.login_rounded,
          label: 'Check In',
          onTap: () {
            Navigator.pop(context);
            context.pushNamed(AppRoutes.addStayName);
          },
        ),
        _MenuItem(
          icon: Icons.logout_rounded,
          label: 'Check Out',
          onTap: () {
            Navigator.pop(context);
            _goBranch(5);
          },
        ),
      ],
    );
  }

  void _showFinanceMenu(BuildContext context) {
    _showMenuSheet(
      context,
      title: 'Finance',
      items: [
        _MenuItem(
          icon: Icons.receipt_long_rounded,
          label: 'Rent Records',
          onTap: () {
            Navigator.pop(context);
            _goBranch(10);
          },
        ),
        _MenuItem(
          icon: Icons.account_balance_rounded,
          label: 'Expenses',
          onTap: () {
            Navigator.pop(context);
            _goBranch(11);
          },
        ),
        _MenuItem(
          icon: Icons.account_balance_wallet_rounded,
          label: 'Deposits',
          onTap: () {
            Navigator.pop(context);
            _goBranch(7);
          },
        ),
        _MenuItem(
          icon: Icons.receipt_rounded,
          label: 'Receipts',
          onTap: () {
            Navigator.pop(context);
            _goBranch(8);
          },
        ),
        _MenuItem(
          icon: Icons.payments_rounded,
          label: 'Payments',
          onTap: () {
            Navigator.pop(context);
            _goBranch(9);
          },
        ),
        _MenuItem(
          icon: Icons.warning_amber_rounded,
          label: 'Damage Charges',
          onTap: () {
            Navigator.pop(context);
            _goBranch(6);
          },
        ),
      ],
    );
  }

  void _showMoreMenu(BuildContext context) {
    _showMenuSheet(
      context,
      title: 'More',
      items: [
        _MenuItem(
          icon: Icons.search_rounded,
          label: 'Search',
          onTap: () {
            Navigator.pop(context);
            _goBranch(0);
          },
        ),
        _MenuItem(
          icon: Icons.analytics_rounded,
          label: 'Reports',
          onTap: () {
            Navigator.pop(context);
            _showComingSoon(context);
          },
        ),
        _MenuItem(
          icon: Icons.backup_rounded,
          label: 'Backup',
          onTap: () {
            Navigator.pop(context);
            _showComingSoon(context);
          },
        ),
        _MenuItem(
          icon: Icons.import_export_rounded,
          label: 'Export',
          onTap: () {
            Navigator.pop(context);
            _showComingSoon(context);
          },
        ),
        _MenuItem(
          icon: Icons.settings_rounded,
          label: 'Settings',
          onTap: () {
            Navigator.pop(context);
            context.pushNamed(AppRoutes.settingsName);
          },
        ),
        _MenuItem(
          icon: Icons.info_rounded,
          label: 'Hostel Information',
          onTap: () {
            Navigator.pop(context);
            _showComingSoon(context);
          },
        ),
        _MenuItem(
          icon: Icons.help_outline_rounded,
          label: 'About',
          onTap: () {
            Navigator.pop(context);
            _showComingSoon(context);
          },
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This feature is coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showMenuSheet(
    BuildContext context, {
    required String title,
    required List<_MenuItem> items,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  padding: const EdgeInsets.only(bottom: 24),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      leading: Icon(item.icon, color: Theme.of(context).colorScheme.primary),
                      title: Text(
                        item.label,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      onTap: item.onTap,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(navigationShell.currentIndex);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) => _onDestinationSelected(context, index),
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme: const IconThemeData(color: AppColors.primary),
                  selectedLabelTextStyle: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_rounded),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.meeting_room_rounded),
                      label: Text('Rooms'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.groups_rounded),
                      label: Text('Tenants'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.account_balance_wallet_rounded),
                      label: Text('Finance'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.menu_rounded),
                      label: Text('More'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: navigationShell),
              ],
            ),
          );
        }

        return Scaffold(
          body: BottomBar(
            borderRadius: BorderRadius.circular(500),
            barColor: Theme.of(context).colorScheme.surfaceContainerHigh.withAlpha(240),
            hideOnScroll: true,
            width: constraints.maxWidth > 500 ? 400 : constraints.maxWidth * 0.9,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _BottomBarItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    isSelected: selectedIndex == 0,
                    onTap: () => _onDestinationSelected(context, 0),
                  ),
                  _BottomBarItem(
                    icon: Icons.meeting_room_rounded,
                    label: 'Rooms',
                    isSelected: selectedIndex == 1,
                    onTap: () => _onDestinationSelected(context, 1),
                  ),
                  _BottomBarItem(
                    icon: Icons.groups_rounded,
                    label: 'Tenants',
                    isSelected: selectedIndex == 2,
                    onTap: () => _onDestinationSelected(context, 2),
                  ),
                  _BottomBarItem(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Finance',
                    isSelected: selectedIndex == 3,
                    onTap: () => _onDestinationSelected(context, 3),
                  ),
                  _BottomBarItem(
                    icon: Icons.menu_rounded,
                    label: 'More',
                    isSelected: selectedIndex == 4,
                    onTap: () => _onDestinationSelected(context, 4),
                  ),
                ],
              ),
            ),
            body: (context, controller) => PrimaryScrollController(
              controller: controller,
              child: navigationShell,
            ),
          ),
        );
      },
    );
  }
}

class _BottomBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BottomBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            decoration: isSelected
                ? BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  )
                : const BoxDecoration(),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}
