import 'package:flutter_test/flutter_test.dart';
import 'package:wearable_app/main.dart';

void main() {
  testWidgets('Wearable app shows initial state', (WidgetTester tester) async {
    await tester.pumpWidget(const WearableApp());
    expect(find.text('Esperando datos...'), findsOneWidget);
  });
}
