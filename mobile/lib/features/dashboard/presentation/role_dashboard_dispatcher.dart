import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import 'executive_dashboard_screen.dart';
import 'tanker_driver_dashboard_screen.dart';
import 'can_delivery_driver_dashboard_screen.dart';
import 'cashier_dashboard_screen.dart';
import 'field_agent_dashboard_screen.dart';

class RoleDashboardDispatcher extends ConsumerWidget {
  const RoleDashboardDispatcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

    final role = (user?.role ?? '').toLowerCase();
    final username = (user?.username ?? user?.name ?? '').toLowerCase();

    if (role == 'tankerdriver' || username == 'tanker_driver' || username == 'tanker') {
      return const TankerDriverDashboardScreen();
    } else if (role == 'deliverydriver' || role == 'driver' || username == 'driver') {
      return const CanDeliveryDriverDashboardScreen();
    } else if (role == 'cashier' || username == 'cashier') {
      return const CashierDashboardScreen();
    } else if (role == 'fieldagent' || role == 'agent' || username == 'agent') {
      return const FieldAgentDashboardScreen();
    }

    // Default to Executive Dashboard for Admin and Super Admin
    return const ExecutiveDashboardScreen();
  }
}
