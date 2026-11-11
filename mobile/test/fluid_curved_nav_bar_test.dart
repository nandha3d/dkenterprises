import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dk_track_mobile/core/ui/fluid_curved_nav_bar.dart';

void main() {
  testWidgets('FluidCurvedNavBar renders 4 tabs and handles tab selection with fluid animation', (tester) async {
    int selectedIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              bottomNavigationBar: FluidCurvedNavBar(
                currentIndex: selectedIndex,
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
                  ),
                  FluidNavItem(
                    icon: Icons.access_time_rounded,
                    activeIcon: Icons.access_time_filled_rounded,
                    label: 'Tasks',
                  ),
                  FluidNavItem(
                    icon: Icons.pie_chart_outline_rounded,
                    activeIcon: Icons.pie_chart_rounded,
                    label: 'Modules',
                  ),
                  FluidNavItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Profile',
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

    // Tap Tab 1 (Tasks)
    await tester.tap(find.byIcon(Icons.access_time_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(selectedIndex, 1);
    expect(find.byIcon(Icons.access_time_filled_rounded), findsOneWidget);

    // Tap Tab 2 (Modules)
    await tester.tap(find.byIcon(Icons.pie_chart_outline_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(selectedIndex, 2);
    expect(find.byIcon(Icons.pie_chart_rounded), findsOneWidget);

    // Tap Tab 3 (Profile)
    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(selectedIndex, 3);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
  });
}
