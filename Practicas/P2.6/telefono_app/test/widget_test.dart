import 'package:flutter_test/flutter_test.dart';
import 'package:telefono_app/main.dart';

void main() {
  testWidgets('Telefono app shows connect button', (WidgetTester tester) async {
    await tester.pumpWidget(const TelefonoApp());
    expect(find.text('Buscar wearable'), findsOneWidget);
  });
}
