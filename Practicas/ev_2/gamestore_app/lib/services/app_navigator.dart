import 'package:flutter/material.dart';

/// Clave global del Navigator para navegar desde fuera del árbol de widgets
/// (ej. cuando el wearable pulsa VER y hay que abrir el juego en el celular).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
