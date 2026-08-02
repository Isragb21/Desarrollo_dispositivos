import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gamestore_app/theme/app_theme.dart';
import 'package:gamestore_app/providers/game_provider.dart';
import 'package:gamestore_app/providers/cart_provider.dart';
import 'package:gamestore_app/providers/wishlist_provider.dart';
import 'package:gamestore_app/providers/wearable_provider.dart';
import 'package:gamestore_app/screens/login_screen.dart';
import 'package:gamestore_app/services/tv_sync.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        ChangeNotifierProvider(
          create: (_) => WearableProvider()..init(),
        ),
        Provider<TvSync>(create: (_) => TvSync()),
      ],
      child: MaterialApp(
        title: 'GAMESTORE',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const LoginScreen(),
      ),
    );
  }
}
