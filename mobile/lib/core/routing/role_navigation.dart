import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../ui/fluid_curved_nav_bar.dart';

/// Immutable navigation tab descriptor mapped to Stitch role navigation specs (English-only).
class RoleNavTab {
  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String tooltip;
  final bool isCenterAction;

  const RoleNavTab({
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.tooltip,
    this.isCenterAction = false,
  });
}

/// Returns the ordered bottom-navigation items for the authenticated [RippleRole].
List<RoleNavTab> navTabsForRole(RippleRole role) {
  return switch (role) {
    RippleRole.admin => const [
        RoleNavTab(
          route: '/home',
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          label: 'Home',
          tooltip: 'Executive Home',
        ),
        RoleNavTab(
          route: '/trade',
          icon: Icons.storefront_outlined,
          activeIcon: Icons.storefront_rounded,
          label: 'Trade',
          tooltip: 'Sales, Purchases & Stock',
        ),
        RoleNavTab(
          route: '',
          icon: Icons.add_rounded,
          activeIcon: Icons.add_rounded,
          label: 'Add',
          tooltip: 'Quick Actions (+)',
          isCenterAction: true,
        ),
        RoleNavTab(
          route: '/money',
          icon: Icons.account_balance_wallet_outlined,
          activeIcon: Icons.account_balance_wallet_rounded,
          label: 'Money',
          tooltip: 'Collections, Expenses & Books',
        ),
        RoleNavTab(
          route: '/modules',
          icon: Icons.grid_view_outlined,
          activeIcon: Icons.grid_view_rounded,
          label: 'More',
          tooltip: 'All Modules & Settings',
        ),
      ],
    RippleRole.driver => const [
        RoleNavTab(
          route: '/home',
          icon: Icons.local_shipping_outlined,
          activeIcon: Icons.local_shipping_rounded,
          label: 'Today',
          tooltip: 'Route & Manifest Today',
        ),
        RoleNavTab(
          route: '/tasks',
          icon: Icons.assignment_outlined,
          activeIcon: Icons.assignment_rounded,
          label: 'Work',
          tooltip: 'Deliveries, Refills & Outbox',
        ),
        RoleNavTab(
          route: '',
          icon: Icons.add_rounded,
          activeIcon: Icons.add_rounded,
          label: 'Add',
          tooltip: 'Quick Actions (+)',
          isCenterAction: true,
        ),
        RoleNavTab(
          route: '/tab/driver-cash',
          icon: Icons.payments_outlined,
          activeIcon: Icons.payments_rounded,
          label: 'Cash',
          tooltip: 'Driver Cash & Settlement',
        ),
        RoleNavTab(
          route: '/profile',
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          label: 'Me',
          tooltip: 'Profile & Attendance',
        ),
      ],
    RippleRole.cafe => const [
        RoleNavTab(
          route: '/home',
          icon: Icons.point_of_sale_outlined,
          activeIcon: Icons.point_of_sale_rounded,
          label: 'Counter',
          tooltip: 'Cafe Counter & POS',
        ),
        RoleNavTab(
          route: '/pos/orders',
          icon: Icons.receipt_long_outlined,
          activeIcon: Icons.receipt_long_rounded,
          label: 'Orders',
          tooltip: 'POS Orders & Held Bills',
        ),
        RoleNavTab(
          route: '',
          icon: Icons.add_rounded,
          activeIcon: Icons.add_rounded,
          label: 'Add',
          tooltip: 'Quick Actions (+)',
          isCenterAction: true,
        ),
        RoleNavTab(
          route: '/pos/drawer',
          icon: Icons.savings_outlined,
          activeIcon: Icons.savings_rounded,
          label: 'Drawer',
          tooltip: 'Cash Drawer & X/Z Report',
        ),
        RoleNavTab(
          route: '/pos/kitchen',
          icon: Icons.soup_kitchen_outlined,
          activeIcon: Icons.soup_kitchen_rounded,
          label: 'Kitchen',
          tooltip: 'Stock Audit & Kitchen Ops',
        ),
      ],
    RippleRole.fieldAgent => const [
        RoleNavTab(
          route: '/home',
          icon: Icons.account_balance_wallet_outlined,
          activeIcon: Icons.account_balance_wallet_rounded,
          label: 'Collect',
          tooltip: 'Field Collection Desk',
        ),
        RoleNavTab(
          route: '/tab/customers',
          icon: Icons.people_outline_rounded,
          activeIcon: Icons.people_rounded,
          label: 'Customers',
          tooltip: 'Customers & KYC',
        ),
        RoleNavTab(
          route: '',
          icon: Icons.add_rounded,
          activeIcon: Icons.add_rounded,
          label: 'Add',
          tooltip: 'Quick Actions (+)',
          isCenterAction: true,
        ),
        RoleNavTab(
          route: '/tab/spend',
          icon: Icons.receipt_outlined,
          activeIcon: Icons.receipt_rounded,
          label: 'Spend',
          tooltip: 'Field Expenses',
        ),
        RoleNavTab(
          route: '/profile',
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          label: 'Me',
          tooltip: 'Profile & Attendance',
        ),
      ],
  };
}

/// Resolves the active navigation index inside [FluidCurvedNavBar] for a URI [path].
int navIndexForLocation(RippleRole role, String path) {
  final tabs = navTabsForRole(role);
  for (int i = 0; i < tabs.length; i++) {
    final tab = tabs[i];
    if (!tab.isCenterAction && tab.route.isNotEmpty && path.startsWith(tab.route)) {
      return i;
    }
  }
  return 0;
}

