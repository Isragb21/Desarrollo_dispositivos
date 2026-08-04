import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:wearable_app/ble_server.dart';
import 'package:wearable_app/main.dart';
import 'package:wearable_app/wearable_view_model.dart';

void main() {
  testWidgets('Muestra el dashboard de sensores por defecto',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => WearableViewModel()),
          Provider<BleServer>(create: (_) => BleServer()),
        ],
        child: const WearableApp(),
      ),
    );

    expect(find.text('MONITOR'), findsOneWidget);
    expect(find.text('PASOS'), findsOneWidget);
    expect(find.text('RITMO'), findsOneWidget);
    expect(find.text('CALORÍAS'), findsOneWidget);
    expect(find.text('INICIAR'), findsOneWidget);
  });

  testWidgets('El botón INICIAR arranca el simulador y cambia a DETENER',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => WearableViewModel()),
          Provider<BleServer>(create: (_) => BleServer()),
        ],
        child: const WearableApp(),
      ),
    );

    await tester.tap(find.text('INICIAR'));
    await tester.pump();

    expect(find.text('DETENER'), findsOneWidget);
  });

  testWidgets('Una compra exitosa del teléfono muestra la pantalla de éxito',
      (WidgetTester tester) async {
    final vm = WearableViewModel();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WearableViewModel>.value(value: vm),
          Provider<BleServer>(create: (_) => BleServer()),
        ],
        child: const WearableApp(),
      ),
    );

    vm.handleEvent(const {'type': 'purchase', 'total': 1299.0, 'games': 3});
    await tester.pump();

    expect(find.text('COMPRA EXITOSA'), findsOneWidget);
    expect(find.text('\$1299.00'), findsOneWidget);
    expect(find.text('3 juego(s) adquirido(s)'), findsOneWidget);
    expect(find.text('INICIO'), findsOneWidget);

    await tester.tap(find.text('INICIO'));
    await tester.pump();
    expect(find.text('MONITOR'), findsOneWidget);
  });
}
