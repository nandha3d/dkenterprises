import 'package:flutter_test/flutter_test.dart';
import 'package:dk_track_mobile/main.dart';

void main() {
  testWidgets('DK Track smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DKTrackApp());
    expect(find.byType(DKTrackApp), findsOneWidget);
  });
}
