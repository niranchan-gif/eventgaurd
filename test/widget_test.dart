import 'package:flutter_test/flutter_test.dart';
import 'package:borderguard_ai/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BorderGuardApp());
    expect(find.byType(BorderGuardApp), findsOneWidget);
  });
}
