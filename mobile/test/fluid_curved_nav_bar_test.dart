import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dk_track_mobile/core/ui/fluid_curved_nav_bar.dart';
import 'package:dk_track_mobile/core/theme/app_colors.dart';

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
}

