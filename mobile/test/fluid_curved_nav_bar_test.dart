import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dk_track_mobile/core/ui/fluid_curved_nav_bar.dart';
import 'package:dk_track_mobile/core/theme/app_colors.dart';
import 'package:dk_track_mobile/core/theme/app_theme.dart';

void main() {
  testWidgets('FluidCurvedNavBar renders 4 tabs and handles tab selection with fluid animation', (tester) async {
    int selectedIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: Container(
                key: const Key('scaffold_body_content'),
                color: Colors.blueGrey,
              ),
              bottomNavigationBar: FluidCurvedNavBar(
                currentIndex: selectedIndex,
                activeColor: AppColors.primary,
                onTabSelected: (index) {
                  setState(() {
                    selectedIndex = index;
                  });
                },
                items: const [
                  FluidNavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Home',
                    tooltip: 'Home Dashboard',
                  ),
                  FluidNavItem(
                    icon: Icons.assignment_outlined,
                    activeIcon: Icons.assignment_rounded,
                    label: 'Tasks',
                    tooltip: 'Operational Tasks',
                  ),
                  FluidNavItem(
                    icon: Icons.grid_view_outlined,
                    activeIcon: Icons.grid_view_rounded,
                    label: 'Modules',
                    tooltip: 'All Menus & Modules',
                  ),
                  FluidNavItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Profile',
                    tooltip: 'Profile & Settings',
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    // Initial state: Tab 0 active
    expect(find.byType(FluidCurvedNavBar), findsOneWidget);
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);

    // Verify bounded height: Navbar MUST be exactly 90.0px and NOT take over the whole screen
    final navBarBox = tester.renderObject<RenderBox>(find.byType(FluidCurvedNavBar));
    expect(navBarBox.size.height, 90.0);

    // Verify Scaffold body has full remaining height (not squished to 0)
    final bodyBox = tester.renderObject<RenderBox>(find.byKey(const Key('scaffold_body_content')));
    expect(bodyBox.size.height, greaterThan(500.0));

    // Tap Tab 1 (Tasks)
    await tester.tap(find.byIcon(Icons.assignment_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(selectedIndex, 1);
    expect(find.byIcon(Icons.assignment_rounded), findsOneWidget);

    // Tap Tab 2 (Modules)
    await tester.tap(find.byIcon(Icons.grid_view_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(selectedIndex, 2);
    expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);

    // Tap Tab 3 (Profile)
    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(selectedIndex, 3);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
  });

  testWidgets('FluidCurvedNavBar renders floating theme-colored 5-menu pill with center + action', (tester) async {
    int selectedIndex = 0;
    int actionTapped = 0;

    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final driverSkin = RippleSkin.forRole(RippleRole.driver, Brightness.light);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.light(primary: driverSkin.primary),
          extensions: [driverSkin],
        ),
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: const SizedBox.expand(),
              bottomNavigationBar: FluidCurvedNavBar(
                currentIndex: selectedIndex,
                onTabSelected: (idx) => setState(() => selectedIndex = idx),
                items: [
                  const FluidNavItem(icon: Icons.local_shipping_outlined, activeIcon: Icons.local_shipping_rounded, label: 'Today'),
                  const FluidNavItem(icon: Icons.assignment_outlined, activeIcon: Icons.assignment_rounded, label: 'Work'),
                  FluidNavItem(
                    icon: Icons.add_rounded,
                    activeIcon: Icons.add_rounded,
                    label: 'Add',
                    isActionOnly: true,
                    onActionTap: () => actionTapped += 1,
                  ),
                  const FluidNavItem(icon: Icons.payments_outlined, activeIcon: Icons.payments_rounded, label: 'Cash'),
                  const FluidNavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Me'),
                ],
              ),
            );
          },
        ),
      ),
    );

    final navBarRect = tester.getRect(find.byType(FluidCurvedNavBar));
    expect(navBarRect.width, 1280.0);
    expect(navBarRect.height, 90.0);

    // Floating pill must stay inset from left, right, and bottom edges (not docked edge-to-edge)
    final pillRect = tester.getRect(find.byKey(const Key('fluid_floating_nav_pill')));
    expect(pillRect.width, 620.0);
    expect(pillRect.left, greaterThan(100.0));
    expect(pillRect.right, lessThan(1180.0));
    expect(navBarRect.bottom - pillRect.bottom, 10.0);

    // Active badge & icon must follow the active RippleSkin theme palette
    final badgeContainer = tester.widget<Container>(find.byKey(const Key('fluid_active_circle_badge')));
    final badgeDecoration = badgeContainer.decoration! as BoxDecoration;
    expect(badgeDecoration.color, driverSkin.navActiveCircle);

    final activeIcon = tester.widget<Icon>(find.byIcon(Icons.local_shipping_rounded));
    expect(activeIcon.color, driverSkin.navActiveIcon);

    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    expect(actionTapped, 1);

    await tester.tap(find.text('Cash'));
    await tester.pumpAndSettle();
    expect(selectedIndex, 3);
  });

  testWidgets('FluidCurvedNavBar stays horizontally inset and floats above bottom on narrow phones', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final cafeSkin = RippleSkin.forRole(RippleRole.cafe, Brightness.light);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.light(primary: cafeSkin.primary),
          extensions: [cafeSkin],
        ),
        home: Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: FluidCurvedNavBar(
            currentIndex: 0,
            onTabSelected: (_) {},
            items: [
              const FluidNavItem(icon: Icons.point_of_sale_outlined, activeIcon: Icons.point_of_sale_rounded, label: 'POS'),
              const FluidNavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, label: 'Orders'),
              FluidNavItem(icon: Icons.add_rounded, label: 'Add', isActionOnly: true, onActionTap: () {}),
              const FluidNavItem(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2_rounded, label: 'Stock'),
              const FluidNavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Me'),
            ],
          ),
        ),
      ),
    );

    final outerRect = tester.getRect(find.byType(FluidCurvedNavBar));
    final pillRect = tester.getRect(find.byKey(const Key('fluid_floating_nav_pill')));
    expect(pillRect.left, 14.0);
    expect(pillRect.right, 390.0 - 14.0);
    expect(outerRect.bottom - pillRect.bottom, 10.0);

    final activeIcon = tester.widget<Icon>(find.byIcon(Icons.point_of_sale_rounded));
    expect(activeIcon.color, cafeSkin.navActiveIcon);
  });
}

