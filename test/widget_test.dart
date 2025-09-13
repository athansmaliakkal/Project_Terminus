import 'package:flutter_test/flutter_test.dart';
import 'package:terminus/main.dart';

void main() {
  testWidgets('App shows PIN Setup screen on first launch smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TerminusApp(initialRoute: '/setup'));
    await tester.pumpAndSettle();
    expect(find.text('Create a 6-digit PIN'), findsOneWidget);
    expect(find.text('Authentication Successful'), findsNothing);
  });
}