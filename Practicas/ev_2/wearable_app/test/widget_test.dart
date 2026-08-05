import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:wearable_app/ble_server.dart';
import 'package:wearable_app/main.dart';
import 'package:wearable_app/wearable_view_model.dart';

Widget _app(WearableViewModel? vm) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<WearableViewModel>(
        create: (_) => vm ?? WearableViewModel(),
      ),
      Provider<BleServer>(create: (_) => BleServer()),
    ],
    child: const WearableApp(),
  );
}

void main() {
  testWidgets('La app arranca bloqueada sin conexión',
      (WidgetTester tester) async {
    await tester.pumpWidget(_app(null));

    expect(find.text('WEARABLE BLOQUEADO'), findsOneWidget);
    expect(find.text('ESTABLECER CONEXIÓN'), findsOneWidget);
  });

  testWidgets('Pulsar ESTABLECER CONEXIÓN entra en espera del teléfono',
      (WidgetTester tester) async {
    await tester.pumpWidget(_app(null));

    await tester.tap(find.text('ESTABLECER CONEXIÓN'));
    await tester.pump();

    expect(find.text('Esperando al teléfono...'), findsOneWidget);
  });

  testWidgets('El evento "pair" desbloquea y muestra el inicio sin sensores',
      (WidgetTester tester) async {
    final vm = WearableViewModel();
    await tester.pumpWidget(_app(vm));

    expect(find.text('WEARABLE BLOQUEADO'), findsOneWidget);

    vm.handleEvent(const {'type': 'pair', 'games': 3});
    await tester.pumpAndSettle();

    expect(find.text('WEARABLE BLOQUEADO'), findsNothing);
    expect(find.text('GAMESTORE'), findsOneWidget);
    expect(find.text('JUEGOS OBTENIDOS'), findsOneWidget);
    expect(find.text('PASOS'), findsNothing);
    expect(find.text('INICIAR'), findsNothing);
  });

  testWidgets('Una compra exitosa del teléfono muestra la pantalla de éxito',
      (WidgetTester tester) async {
    final vm = WearableViewModel();
    await tester.pumpWidget(_app(vm));

    vm.handleEvent(const {'type': 'pair', 'games': 3});
    await tester.pumpAndSettle();
    vm.handleEvent(const {'type': 'purchase', 'total': 1299.0, 'games': 3});
    await tester.pumpAndSettle();

    expect(find.text('COMPRA EXITOSA'), findsOneWidget);
    expect(find.text('\$1299.00'), findsOneWidget);
    expect(find.text('3 juego(s) adquirido(s)'), findsOneWidget);
    expect(find.text('INICIO'), findsOneWidget);

    await tester.tap(find.text('INICIO'));
    await tester.pumpAndSettle();
    expect(find.text('GAMESTORE'), findsOneWidget);
  });
}
