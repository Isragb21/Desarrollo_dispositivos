import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gamestore_app/theme/app_theme.dart';
import 'package:gamestore_app/providers/game_provider.dart';
import 'package:gamestore_app/providers/cart_provider.dart';
import 'package:gamestore_app/providers/wishlist_provider.dart';
import 'package:gamestore_app/providers/wearable_provider.dart';
import 'package:gamestore_app/screens/login_screen.dart';
import 'package:gamestore_app/services/app_navigator.dart';
import 'package:gamestore_app/services/notifier_service.dart';
import 'package:gamestore_app/services/offer_service.dart';
import 'package:gamestore_app/services/tv_sync.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notificationsGranted = await NotifierService.instance.init();
  await OfferService.initialize();
  if (notificationsGranted) {
    await OfferService.start();
  }
  runApp(const GameStoreApp());
}

class GameStoreApp extends StatelessWidget {
  const GameStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => WearableProvider()..init()),
        Provider<TvSync>(create: (_) => TvSync()),
      ],
      child: MaterialApp(
        title: 'GAMESTORE',
        debugShowCheckedModeBanner: false,
        navigatorKey: appNavigatorKey,
        theme: AppTheme.darkTheme,
        home: const LoginScreen(),
      ),
    );
  }
}
