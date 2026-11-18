import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import 'can_delivery_driver_dashboard_screen.dart';
import 'cashier_dashboard_screen.dart';
import 'executive_dashboard_screen.dart';
import 'field_agent_dashboard_screen.dart';
import 'tanker_driver_dashboard_screen.dart';

class RoleDashboardDispatcher extends ConsumerWidget {
  const RoleDashboardDispatcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rippleRole = ref.watch(activeRippleRoleProvider);
    final driverFlavor = ref.watch(activeDriverFlavorProvider);

    return switch (rippleRole) {
      RippleRole.driver => driverFlavor == RippleDriverFlavor.tanker
          ? const TankerDriverDashboardScreen()
          : const CanDeliveryDriverDashboardScreen(),
      RippleRole.cafe => const CashierDashboardScreen(),
      RippleRole.fieldAgent => const FieldAgentDashboardScreen(),
      RippleRole.admin => const ExecutiveDashboardScreen(),
    };
  }
}
