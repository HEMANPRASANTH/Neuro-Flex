// This is a basic Flutter widget test.
import 'package:flutter_test/flutter_test.dart';
import 'package:neuroflex/main.dart'; // Ensure this matches your project name

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // FIXED: Changed MyApp() to NeuroFlexApp()
    await tester.pumpWidget(const NeuroFlexApp());

    // Verify that the app starts and finds the title "NeuroFlex"
    expect(find.text('NeuroFlex'), findsOneWidget);
  });
}
