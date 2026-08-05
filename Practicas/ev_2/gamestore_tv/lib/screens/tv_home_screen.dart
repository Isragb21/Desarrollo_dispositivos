import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gamestore_tv/models/game.dart';
import 'package:gamestore_tv/services/api_service.dart';
import 'package:gamestore_tv/services/tv_sync.dart';
import 'package:gamestore_tv/theme/tv_theme.dart';
import 'package:gamestore_tv/widgets/game_card.dart';
import 'package:gamestore_tv/widgets/video_background.dart';

/// Pantalla principal TV (1920x1080, sin scroll, safe zone 5%).
/// Destacado del juego seleccionado + rail horizontal con todo el catalogo.
/// Recibe el carrito del teléfono vía BroadcastChannel (origin validado).
class TvHomeScreen extends StatefulWidget {
  const TvHomeScreen({super.key});

  @override
  State<TvHomeScreen> createState() => _TvHomeScreenState();
}

class _TvHomeScreenState extends State<TvHomeScreen> {
  int _sidebarIndex = 0;

  // Rail horizontal: muestra hasta 5 tarjetas, navega por todos los juegos.
  static const int _railVisible = 5;
  static const double _railHeight = 320;

  List<Game> _games = [];
  int _selected = 0;
  bool _loading = true;
  bool _apiOnline = false;
  DateTime _now = DateTime.now();
  Timer? _clockTimer;

  // Datos sincronizados desde el teléfono (BroadcastChannel).
  TvSync? _tvSync;
  StreamSubscription<Map<String, dynamic>>? _tvSyncSub;
  double _phoneCartTotal = 0.0;
  int _phoneCartCount = 0;
  bool _phoneConnected = false;

  @override
  void initState() {
    super.initState();
    _loadGames();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _initTvSync();
  }

  void _initTvSync() {
    final tvSync = TvSync();
    _tvSync = tvSync;
    tvSync.open();
    _tvSyncSub = tvSync.messages.listen((message) {
      if (!mounted) return;
      switch (message['type']) {
        case 'cart':
          setState(() {
            _phoneCartTotal =
                (message['total'] as num?)?.toDouble() ?? _phoneCartTotal;
            _phoneCartCount =
                (message['count'] as num?)?.toInt() ?? _phoneCartCount;
            _phoneConnected = true;
          });
          break;
        case 'purchase':
          setState(() {
            _phoneCartTotal = 0.0;
            _phoneCartCount = 0;
            _phoneConnected = true;
          });
          break;
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _tvSyncSub?.cancel();
    _tvSync?.close();
    super.dispose();
  }

  Future<void> _loadGames() async {
    setState(() => _loading = true);
    final games = await ApiService.fetchGames();
    if (!mounted) return;
    setState(() {
      _games = games;
      _selected = 0;
      _loading = false;
      _apiOnline = games.isNotEmpty;
    });
  }

  Game? get _selectedGame => _games.isEmpty ? null : _games[_selected];

  /// Navega el rail en circulo (izq/der y arriba/abajo avanzan por los juegos).
  void _move(int dx) {
    if (_games.isEmpty) return;
    final next = (_selected + dx) % _games.length;
    if (next != _selected) {
      setState(() => _selected = next);
      _broadcastSelection();
    }
  }

  /// Informa al teléfono (BroadcastChannel) el juego seleccionado en la TV.
  void _broadcastSelection() {
    final game = _selectedGame;
    if (game == null) return;
    _tvSync?.broadcast('tv_selection', {'game': game.title});
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    // Navegación enfocada solo si estamos en el dashboard
    if (_sidebarIndex != 0) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        _move(-1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        _move(1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        _move(-1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        _move(1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.select:
        setState(() {});
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _SplashScreen();

    return Scaffold(
      backgroundColor: TvColors.background,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Focus(
              autofocus: true,
              onKeyEvent: _onKeyEvent,
              child: IndexedStack(
                index: _sidebarIndex,
                children: [
                  _buildDashboard(),
                  const Center(
                    child: Text("BÚSQUEDA", style: TextStyle(fontSize: 48)),
                  ),
                  const Center(
                    child: Text("BIBLIOTECA", style: TextStyle(fontSize: 48)),
                  ),
                  const Center(
                    child: Text("PERFIL", style: TextStyle(fontSize: 48)),
                  ),
                  const Center(
                    child: Text(
                      "CONFIGURACIÓN",
                      style: TextStyle(fontSize: 48),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 80,
      decoration: const BoxDecoration(
        color: TvColors.surface,
        border: Border(
          right: BorderSide(color: TvColors.textSecondary, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          const Text(
            "GS",
            style: TextStyle(
              color: TvColors.neonGreen,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 48),
          _buildSidebarIcon(0, Icons.home_outlined),
          _buildSidebarIcon(1, Icons.search),
          _buildSidebarIcon(2, Icons.library_books_outlined),
          _buildSidebarIcon(3, Icons.person_outline),
          const Spacer(),
          _buildSidebarIcon(4, Icons.settings_outlined),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSidebarIcon(int index, IconData icon) {
    final isSelected = _sidebarIndex == index;
    return IconButton(
      icon: Icon(
        icon,
        color: isSelected ? TvColors.neonGreen : TvColors.textSecondary,
        size: 32,
      ),
      onPressed: () => setState(() => _sidebarIndex = index),
      padding: const EdgeInsets.symmetric(vertical: 24),
    );
  }

  Widget _buildDashboard() {
    return Stack(
      fit: StackFit.expand,
      children: [
        _Background(selected: _selectedGame),
        SafeArea(
          child: Padding(
            // Safe zone 5%: 54px vertical, 96px horizontal (SA.2.B)
            padding: const EdgeInsets.symmetric(horizontal: 96, vertical: 54),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                if (_phoneConnected) ...[
                  const SizedBox(height: 16),
                  _buildPhoneSyncBanner(context),
                ],
                const SizedBox(height: 28),
                Expanded(child: _buildFeatured(context, _selectedGame)),
                const SizedBox(height: 24),
                _buildRail(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final time = _now.toLocal();
    final fecha =
        "${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year}";
    final hora =
        "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}";
    return Row(
      children: [
        const Icon(Icons.live_tv, color: TvColors.neonGreen, size: 40),
        const SizedBox(width: 16),
        Text(
          "GAMESTORE TV",
          style: GoogleFontsStyle.spaceGrotesk(32, bold: true),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(
              color: _apiOnline ? TvColors.neonGreen : TvColors.error,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _apiOnline ? Icons.circle : Icons.error_outline,
                color: _apiOnline ? TvColors.neonGreen : TvColors.error,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _apiOnline ? "API EN LÍNEA" : "SIN CONEXIÓN",
                style: TextStyle(
                  color: _apiOnline ? TvColors.neonGreen : TvColors.error,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Text(
          "$fecha   $hora",
          style: const TextStyle(
            color: TvColors.textSecondary,
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Banner de sincronización con el teléfono (carrito vía BroadcastChannel).
  Widget _buildPhoneSyncBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: TvColors.neonGreen.withValues(alpha: 0.12),
        border: Border.all(color: TvColors.neonGreen),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sync, color: TvColors.neonGreen, size: 24),
          const SizedBox(width: 12),
          const Text(
            "CARRITO TELÉFONO SINCRONIZADO",
            style: TextStyle(
              color: TvColors.neonGreen,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            "\$${_phoneCartTotal.toStringAsFixed(2)} · $_phoneCartCount ARTÍCULOS",
            style: const TextStyle(
              color: TvColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatured(BuildContext context, Game? game) {
    if (game == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 120, color: TvColors.error),
            const SizedBox(height: 24),
            Text(
              "NO SE PUDO CARGAR EL CATÁLOGO",
              style: GoogleFontsStyle.spaceGrotesk(40, bold: true),
            ),
            const SizedBox(height: 16),
            const Text(
              "Verifica que la API esté en línea y presiona Enter",
              style: TextStyle(color: TvColors.textSecondary, fontSize: 28),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: _loadGames,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                child: Text("REINTENTAR", style: TextStyle(fontSize: 28)),
              ),
            ),
          ],
        ),
      );
    }

    final precio = game.isOnSale ? game.salePrice! : game.price;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "DESTACADO",
          style: TextStyle(
            color: TvColors.neonGreen,
            fontSize: 32,
            fontWeight: FontWeight.w600,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFontsStyle.spaceGrotesk(48, bold: true),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.star, color: TvColors.gold, size: 32),
                        const SizedBox(width: 8),
                        Text(
                          game.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: TvColors.gold,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: TvColors.neonGreen),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            game.genre.toUpperCase(),
                            style: const TextStyle(
                              color: TvColors.neonGreen,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      game.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: TvColors.textSecondary,
                        fontSize: 24,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: game.tags
                          .map(
                            (t) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: TvColors.neonGreen.withValues(
                                  alpha: 0.1,
                                ),
                                border: Border.all(color: TvColors.neonGreen),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                t,
                                style: const TextStyle(
                                  color: TvColors.neonGreen,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        if (game.isOnSale) ...[
                          Text(
                            "\$ ${game.price.toStringAsFixed(2)}",
                            style: const TextStyle(
                              color: TvColors.textSecondary,
                              fontSize: 32,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        Text(
                          "\$ $precio",
                          style: GoogleFontsStyle.spaceGrotesk(
                            88,
                            bold: true,
                            color: game.isOnSale
                                ? TvColors.error
                                : TvColors.neonGreen,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          "◀ ▶ NAVEGA · ENTER SELECCIONA",
                          style: TextStyle(
                            color: TvColors.textSecondary,
                            fontSize: 24,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Rail horizontal de juegos (SA.2.B): hasta [_railVisible] tarjetas visibles
  /// y la seleccion desplaza la ventana para alcanzar todo el catalogo.
  Widget _buildRail() {
    final games = _games;
    if (games.isEmpty) return const SizedBox.shrink();

    final maxStart = games.length > _railVisible ? games.length - _railVisible : 0;
    final start = (_selected - _railVisible ~/ 2).clamp(0, maxStart);
    final end = (start + _railVisible) > games.length
        ? games.length
        : start + _railVisible;
    final visible = games.sublist(start, end);

    return SizedBox(
      height: _railHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < visible.length; i++) ...[
            Expanded(
              child: GameCard(
                game: visible[i],
                focused: (start + i) == _selected,
                onSelect: () => setState(() => _selected = start + i),
              ),
            ),
            if (i < visible.length - 1) const SizedBox(width: 24),
          ],
        ],
      ),
    );
  }
}

class GoogleFontsStyle {
  static TextStyle spaceGrotesk(
    double size, {
    bool bold = false,
    Color? color,
  }) {
    return TextStyle(
      color: color ?? TvColors.textPrimary,
      fontSize: size,
      fontWeight: bold ? FontWeight.bold : FontWeight.w600,
      letterSpacing: -0.02,
    );
  }
}

/// Fondo del juego seleccionado (SA.2.C / DE.1).
///
/// Base: backdrop HD 1920x1080 (imagen generada en el backend) claveada por
/// [Game.id] para que el cambio de juego sea inmediato y nitido.
/// Overlay: video del juego solo si existe, translucido para no tapar la imagen.
/// Si la imagen falla, cae al poster original de la API.
class _Background extends StatelessWidget {
  final Game? selected;
  const _Background({required this.selected});

  @override
  Widget build(BuildContext context) {
    if (selected == null) return _fallback();
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          ApiService.backdropUrl(selected!.imageUrl),
          key: ValueKey(selected!.id),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _imageFallback(selected!),
        ),
        if (ApiService.hasVideo(selected!.imageUrl))
          VideoBackground(
            src: ApiService.videoUrl(selected!.imageUrl),
            fallback: const SizedBox.shrink(),
          ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.center,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0xE60B0E14)],
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x990B0E14), Color(0xCC0B0E14)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _imageFallback(Game game) {
    return Image.network(
      ApiService.imageUrl(game.imageUrl),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      color: TvColors.background,
      child: Center(
        child: Icon(
          Icons.movie_outlined,
          size: 200,
          color: TvColors.neonGreen.withValues(alpha: 0.15),
        ),
      ),
    );
  }
}

/// Splash screen mientras se cargan datos de la API (DE.1).
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TvColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.live_tv, color: TvColors.neonGreen, size: 120),
            const SizedBox(height: 24),
            Text(
              "GAMESTORE TV",
              style: GoogleFontsStyle.spaceGrotesk(48, bold: true),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                color: TvColors.neonGreen,
                strokeWidth: 6,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "CARGANDO CATÁLOGO...",
              style: TextStyle(
                color: TvColors.textSecondary,
                fontSize: 24,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
