import 'package:flutter/material.dart';
import 'package:gamestore_tv/screens/tv_home_screen.dart';
import 'package:gamestore_tv/theme/tv_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GameStoreTv());
}

class GameStoreTv extends StatelessWidget {
  const GameStoreTv({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GameStore TV',
      debugShowCheckedModeBanner: false,
      theme: TvTheme.darkTheme,
      home: const TvHomeScreen(),
    );
  }
}
