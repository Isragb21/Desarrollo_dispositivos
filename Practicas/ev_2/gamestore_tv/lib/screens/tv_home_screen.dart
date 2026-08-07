import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gamestore_tv/models/game.dart';
import 'package:gamestore_tv/models/tv_user.dart';
import 'package:gamestore_tv/screens/tv_login_screen.dart';
import 'package:gamestore_tv/screens/tv_profile_edit_screen.dart';
import 'package:gamestore_tv/services/api_service.dart';
import 'package:gamestore_tv/services/tv_sync.dart';
import 'package:gamestore_tv/theme/tv_theme.dart';
import 'package:gamestore_tv/widgets/game_card.dart';
import 'package:gamestore_tv/widgets/video_background.dart';

/// Pantalla principal TV (1920x1080, sin scroll, safe zone 5%).
/// Dashboard (destacado + rail) + Búsqueda, Biblioteca, Perfil y Configuración.
/// La sesión se maneja con [ApiService.currentUser]; si no hay sesión,
/// Perfil y Biblioteca muestran "Necesitas iniciar sesión".
class TvHomeScreen extends StatefulWidget {
  const TvHomeScreen({super.key});

  @override
  State<TvHomeScreen> createState() => _TvHomeScreenState();
}

class _TvHomeScreenState extends State<TvHomeScreen> {
  static const int _tabCount = 5;

  int _sidebarIndex = 0;

  // Rail horizontal del dashboard: muestra hasta 5 tarjetas.
  static const int _railVisible = 5;
  static const double _railHeight = 320;

  List<Game> _games = [];
  int _selected = 0;
  bool _loading = true;
  bool _apiOnline = false;
  DateTime _now = DateTime.now();
  Timer? _clockTimer;

  // Foco raíz para que las teclas del D-pad siempre lleguen al navegador.
  final _rootFocus = FocusNode();
  // Foco para la barra lateral (navegación tipo Netflix).
  final _sidebarFocus = FocusNode();
  int _sidebarIconFocus = 0;

  // Búsqueda (tab 1).
  final _searchFocus = FocusNode();
  final _searchController = TextEditingController();
  List<Game> _searchResults = [];
  int _searchSelected = 0;
  bool _searchLoading = false;
  bool _searched = false;

  // Perfil (tab 3): botones seleccionados (0 editar, 1 cerrar sesión).
  int _profileSelected = 0;

  // Biblioteca (tab 2): juegos poseídos del usuario con sesión.
  List<Game> _ownedGames = [];
  int _librarySelected = 0;
  bool _libraryLoading = false;

  // Configuración (tab 4).
  static const int _settingsCount = 2;
  int _settingsSelected = 0;
  bool _notificationsEnabled = true;
  bool _powerSaveEnabled = false;

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
    if (ApiService.currentUser != null) _restoreSessionAndLibrary();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _initTvSync();
    // El TextField de Búsqueda se traga las flechas ↑/↓ (shortcuts de
    // EditableText con DoNothingAndStopPropagation) y nunca llegan al handler
    // raíz. Este handler global corre ANTES del dispatch de foco y garantiza
    // que ↑/↓ siempre naveguen la barra lateral desde la pestaña Búsqueda.
    HardwareKeyboard.instance.addHandler(_hardwareKeys);
  }

  Future<void> _restoreSessionAndLibrary() async {
    final user = ApiService.currentUser;
    if (user == null) return;
    final full = await ApiService.fetchUser(user.id);
    if (full != null) ApiService.currentUser = full;
    await _loadLibrary();
    if (mounted) setState(() {});
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
          _refreshAfterPurchase();
          break;
      }
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_hardwareKeys);
    _rootFocus.dispose();
    _sidebarFocus.dispose();
    _searchFocus.dispose();
    _searchController.dispose();
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

  /// Carga los juegos poseídos (biblioteca) del usuario con sesión.
  Future<void> _loadLibrary() async {
    final user = ApiService.currentUser;
    if (user == null) return;
    setState(() => _libraryLoading = true);
    final games = await ApiService.fetchOwnedGames(user.id);
    if (!mounted) return;
    setState(() {
      _ownedGames = games;
      _librarySelected = 0;
      _libraryLoading = false;
    });
  }

  /// Tras una compra desde el teléfono, refresca el perfil y la biblioteca.
  Future<void> _refreshAfterPurchase() async {
    final user = ApiService.currentUser;
    if (user == null) return;
    final full = await ApiService.fetchUser(user.id);
    if (full != null) {
      ApiService.currentUser = full;
      await _loadLibrary();
      if (mounted) setState(() {});
    }
  }

  /// Cambia de pestaña (índice circular 0..4). Al entrar en Búsqueda enfoca el
  /// campo de texto; al salir devuelve el foco a la raíz del navegador.
  void _changeTab(int index) {
    final target = ((index % _tabCount) + _tabCount) % _tabCount;
    if (_sidebarIndex == 1 && target != 1) _searchFocus.unfocus();
    setState(() => _sidebarIndex = target);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (target == 1) {
        _searchFocus.requestFocus();
      } else {
        _rootFocus.requestFocus();
      }
    });
  }

  // ---------------- Teclado D-pad (por pestaña) ----------------

  /// Handler global (HardwareKeyboard): intercepta ↑/↓ antes de que el
  /// TextField de Búsqueda los consuma, para que desde esa pestaña siempre
  /// naveguen la barra lateral (Inicio arriba, Biblioteca abajo).
  bool _hardwareKeys(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (_sidebarIndex != 1) return false;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        _changeTab(_sidebarIndex - 1);
        return true;
      case LogicalKeyboardKey.arrowDown:
        _changeTab(_sidebarIndex + 1);
        return true;
      default:
        return false;
    }
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    switch (_sidebarIndex) {
      case 0:
        return _dashboardKeys(event.logicalKey);
      case 1:
        return _searchKeys(event.logicalKey);
      case 2:
        return _libraryKeys(event.logicalKey);
      case 3:
        return _profileKeys(event.logicalKey);
      case 4:
        return _settingsKeys(event.logicalKey);
      default:
        return KeyEventResult.ignored;
    }
  }

  /// Dashboard: ←/→ solo mueven los juegos del rail; ↑/↓ cambian de pestaña
  /// siguiendo el orden vertical de la barra lateral (Inicio, Búsqueda,
  /// Biblioteca, Perfil, Configuración).
  KeyEventResult _dashboardKeys(LogicalKeyboardKey key) {
    switch (key) {
      case LogicalKeyboardKey.arrowUp:
        _changeTab(_sidebarIndex - 1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        _changeTab(_sidebarIndex + 1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        if (_games.isNotEmpty && _selected == 0) {
          // En el primer juego, mover foco al sidebar (Netflix-like)
          _sidebarIconFocus = 0; // Home
          _sidebarFocus.requestFocus();
        } else {
          _move(-1);
        }
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

  KeyEventResult _searchKeys(LogicalKeyboardKey key) {
    final fieldFocused = _searchFocus.hasFocus;
    final hasResults = _searchResults.isNotEmpty;
    switch (key) {
      case LogicalKeyboardKey.arrowUp:
        _changeTab(_sidebarIndex - 1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        _changeTab(_sidebarIndex + 1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        if (!fieldFocused && hasResults) {
          if (_searchSelected == 0) {
            _changeTab(0);
          } else {
            setState(() => _searchSelected--);
          }
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        if (!fieldFocused && hasResults) {
          if (_searchSelected == _searchResults.length - 1) {
            _changeTab(2);
          } else {
            setState(() => _searchSelected++);
          }
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.select:
        if (fieldFocused) {
          // Con el campo enfocado, Enter debe llegar al TextField para que
          // onSubmitted ejecute la búsqueda (si lo marcamos handled aquí,
          // el evento se traga y la búsqueda nunca corre).
          return KeyEventResult.ignored;
        }
        if (hasResults) _openSearchResult();
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  KeyEventResult _libraryKeys(LogicalKeyboardKey key) {
    switch (key) {
      case LogicalKeyboardKey.arrowUp:
        _changeTab(_sidebarIndex - 1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        _changeTab(_sidebarIndex + 1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        if (_ownedGames.isNotEmpty) {
          if (_librarySelected == 0) {
            // Si estamos en el primer juego, movemos el foco al sidebar
            _sidebarIconFocus = 2; // Biblioteca
            _sidebarFocus.requestFocus();
          } else {
            setState(() => _librarySelected--);
          }
        } else {
          _changeTab(1);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        if (_ownedGames.isNotEmpty) {
          if (_librarySelected == _ownedGames.length - 1) {
            _changeTab(3);
          } else {
            setState(() => _librarySelected++);
          }
        } else {
          _changeTab(3);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.select:
        if (ApiService.currentUser == null) {
          _startLogin();
        } else if (_ownedGames.isNotEmpty) {
          _openLibraryGame();
        }
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  KeyEventResult _profileKeys(LogicalKeyboardKey key) {
    final user = ApiService.currentUser;
    switch (key) {
      case LogicalKeyboardKey.arrowLeft:
        _changeTab(2);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        _changeTab(4);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        if (user != null) setState(() => _profileSelected = 0);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        if (user != null) setState(() => _profileSelected = 1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.select:
        if (user == null) {
          _startLogin();
        } else if (_profileSelected == 0) {
          _openEditProfile();
        } else {
          _logout();
        }
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  KeyEventResult _settingsKeys(LogicalKeyboardKey key) {
    switch (key) {
      case LogicalKeyboardKey.arrowLeft:
        _changeTab(3);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        _changeTab(0);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        setState(() {
          _settingsSelected =
              (_settingsSelected - 1 + _settingsCount) % _settingsCount;
        });
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        setState(() {
          _settingsSelected = (_settingsSelected + 1) % _settingsCount;
        });
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.select:
        _toggleSetting();
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  // Handler de teclado específico para la barra lateral.
  KeyEventResult _onSidebarKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        setState(() {
          _sidebarIconFocus = (_sidebarIconFocus - 1 + _tabCount) % _tabCount;
        });
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        setState(() {
          _sidebarIconFocus = (_sidebarIconFocus + 1) % _tabCount;
        });
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        // Regresa al contenido: mantener la pestaña actual y dar foco raíz
        _rootFocus.requestFocus();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.select:
        // Cambia a la pestaña seleccionada desde el sidebar
        setState(() => _sidebarIndex = _sidebarIconFocus);
        // Dejar foco en el contenido para que las flechas controlen la vista
        _rootFocus.requestFocus();
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  // ---------------- Acciones ----------------

  void _move(int dx) {
    if (_games.isEmpty) return;
    final next = (_selected + dx) % _games.length;
    if (next != _selected) {
      setState(() => _selected = next);
      _broadcastSelection();
    }
  }

  void _broadcastSelection() {
    final game = _selectedGame;
    if (game == null) return;
    _tvSync?.broadcast('tv_selection', {'game': game.title});
  }

  Future<void> _startLogin() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const TvLoginScreen()),
    );
    if (!mounted || result == null) return;
    ApiService.currentUser = TvUser.fromJson(result);
    final full = await ApiService.fetchUser(ApiService.currentUser!.id);
    if (full != null) ApiService.currentUser = full;
    ApiService.saveSession();
    await _loadLibrary();
    if (mounted) setState(() {});
  }

  Future<void> _openEditProfile() async {
    if (ApiService.currentUser == null) return;
    await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(builder: (_) => const TvProfileEditScreen()),
    );
    if (mounted) setState(() {});
  }

  void _logout() {
    ApiService.clearSession();
    setState(() {
      _ownedGames = [];
      _librarySelected = 0;
    });
  }

  Future<void> _runSearch() async {
    final q = _searchController.text.trim();
    setState(() {
      _searchLoading = true;
      _searched = true;
    });
    _searchFocus.unfocus();
    _rootFocus.requestFocus();
    final results = await ApiService.fetchGames(search: q.isEmpty ? null : q);
    if (!mounted) return;
    setState(() {
      _searchResults = results;
      _searchSelected = 0;
      _searchLoading = false;
    });
  }

  void _openSearchResult() {
    final game =
        _searchResults.isEmpty ? null : _searchResults[_searchSelected];
    if (game == null) return;
    final idx = _games.indexWhere((g) => g.id == game.id);
    if (idx >= 0) setState(() => _selected = idx);
    _changeTab(0);
  }

  /// Abre un juego poseído en el destacado del dashboard (como en búsqueda).
  void _openLibraryGame() {
    if (_ownedGames.isEmpty) return;
    final game = _ownedGames[_librarySelected];
    final idx = _games.indexWhere((g) => g.id == game.id);
    if (idx >= 0) setState(() => _selected = idx);
    _changeTab(0);
  }

  void _toggleSetting() {
    setState(() {
      switch (_settingsSelected) {
        case 0:
          _notificationsEnabled = !_notificationsEnabled;
          break;
        case 1:
          _powerSaveEnabled = !_powerSaveEnabled;
          break;
      }
    });
  }

  // ---------------- Build ----------------

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
              focusNode: _rootFocus,
              autofocus: true,
              onKeyEvent: _onKeyEvent,
              child: IndexedStack(
                index: _sidebarIndex,
                children: [
                  _buildDashboard(),
                  _buildSearch(),
                  _buildLibrary(),
                  _buildProfile(),
                  _buildSettings(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Focus(
      focusNode: _sidebarFocus,
      onKeyEvent: _onSidebarKeyEvent,
      child: Container(
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
      ),
    );
  }

  Widget _buildSidebarIcon(int index, IconData icon) {
    final isSelected = _sidebarIndex == index;
    final isFocusSelected = _sidebarFocus.hasFocus && _sidebarIconFocus == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: () {
          setState(() => _sidebarIndex = index);
          _rootFocus.requestFocus();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: isFocusSelected
                ? TvColors.neonGreen.withValues(alpha: 0.12)
                : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: isFocusSelected ? TvColors.gold : Colors.transparent,
                width: isFocusSelected ? 4 : 0,
              ),
            ),
          ),
          child: Icon(
            icon,
            color: isSelected || isFocusSelected ? TvColors.neonGreen : TvColors.textSecondary,
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildTabTitle(String title) {
    return Text(title, style: GoogleFontsStyle.spaceGrotesk(48, bold: true));
  }

  /// Contenido compartido por pestañas con "zona segura" del 5% (SA.2.B).
  Widget _buildTabShell(List<Widget> children) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 96, vertical: 54),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
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

  // ---------------- Búsqueda ----------------

  Widget _buildSearch() {
    return _buildTabShell([
      _buildTabTitle('BÚSQUEDA'),
      const SizedBox(height: 8),
      const Text(
        'Busca por título, género o descripción · Enter para buscar',
        style: TextStyle(color: TvColors.textSecondary, fontSize: 24),
      ),      const SizedBox(height: 32),
      TextField(
        focusNode: _searchFocus,
        controller: _searchController,
        style: const TextStyle(color: TvColors.textPrimary, fontSize: 28),
        cursorColor: TvColors.neonGreen,
        onSubmitted: (_) => _runSearch(),
        decoration: InputDecoration(
          hintText: 'Buscar juegos...',
          hintStyle: const TextStyle(color: TvColors.textSecondary, fontSize: 28),
          prefixIcon: const Icon(Icons.search, color: TvColors.neonGreen, size: 32),
          filled: true,
          fillColor: TvColors.surface,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: TvColors.textSecondary),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: TvColors.gold, width: 3),
          ),
        ),
      ),
      const SizedBox(height: 32),
      Expanded(child: _buildSearchBody()),
    ]);
  }

  Widget _buildSearchBody() {
    if (_searchLoading) {
      return const Center(
        child: CircularProgressIndicator(color: TvColors.neonGreen),
      );
    }
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 96, color: TvColors.textSecondary),
            const SizedBox(height: 24),
            Text(
              _searched ? 'SIN RESULTADOS' : 'ESCRIBE Y PRESIONA ENTER',
              style: GoogleFontsStyle.spaceGrotesk(40, bold: true),
            ),
            const SizedBox(height: 12),
            const Text(
              '↑ ↓ cambia de sección · ← → navega resultados',
              style: TextStyle(color: TvColors.textSecondary, fontSize: 24),
            ),
          ],
        ),
      );
    }
    return _buildSearchRail();
  }

  Widget _buildSearchRail() {
    final games = _searchResults;
    final maxStart =
        games.length > _railVisible ? games.length - _railVisible : 0;
    final start = (_searchSelected - _railVisible ~/ 2).clamp(0, maxStart);
    final end =
        (start + _railVisible) > games.length ? games.length : start + _railVisible;
    final visible = games.sublist(start, end);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${games.length} RESULTADOS',
          style: const TextStyle(
            color: TvColors.neonGreen,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < visible.length; i++) ...[
                Expanded(
                  child: GameCard(
                    game: visible[i],
                    focused: (start + i) == _searchSelected,
                    onSelect: _openSearchResult,
                  ),
                ),
                if (i < visible.length - 1) const SizedBox(width: 24),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ---------------- Biblioteca ----------------

  Widget _buildLibrary() {
    final user = ApiService.currentUser;
    if (user == null) return _buildLoginRequired('BIBLIOTECA');
    return _buildTabShell([
      _buildTabTitle('BIBLIOTECA'),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: _buildStatCard(
              Icons.library_books_outlined,
              '${user.gamesOwned}',
              'JUEGOS POSEÍDOS',
              onTap: () {
                // Lleva la atención a la lista de juegos poseídos
                setState(() {
                  _librarySelected = 0;
                });
                _rootFocus.requestFocus();
              },
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: _buildStatCard(
              Icons.military_tech_outlined,
              '${user.level}',
              'NIVEL',
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: _buildStatCard(Icons.bolt, '${user.xp}', 'PUNTOS DE EXPERIENCIA'),
          ),
        ],
      ),
      const SizedBox(height: 36),
      Row(
        children: [
          Text(
            '${_ownedGames.length} JUEGOS',
            style: const TextStyle(
              color: TvColors.neonGreen,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          const Text(
            '◀ ▶ NAVEGA · ENTER ABRE',
            style: TextStyle(
              color: TvColors.textSecondary,
              fontSize: 24,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Expanded(child: _buildLibraryRail()),
    ]);
  }

  /// Rail de juegos poseídos: tarjetas con portada, calificación, precio y
  /// foco dorado (mismo estilo que el rail del dashboard).
  Widget _buildLibraryRail() {
    if (_libraryLoading) {
      return const Center(
        child: CircularProgressIndicator(color: TvColors.neonGreen),
      );
    }
    final games = _ownedGames;
    if (games.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videogame_asset_off,
                size: 96, color: TvColors.textSecondary),
            const SizedBox(height: 24),
            Text(
              'NO TIENES JUEGOS',
              style: GoogleFontsStyle.spaceGrotesk(40, bold: true),
            ),
            const SizedBox(height: 12),
            const Text(
              'Los juegos que compres en tu teléfono aparecerán aquí',
              style: TextStyle(color: TvColors.textSecondary, fontSize: 24),
            ),
          ],
        ),
      );
    }

    final maxStart = games.length > _railVisible ? games.length - _railVisible : 0;
    final start = (_librarySelected - _railVisible ~/ 2).clamp(0, maxStart);
    final end = (start + _railVisible) > games.length ? games.length : start + _railVisible;
    final visible = games.sublist(start, end);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          Expanded(
            child: GameCard(
              game: visible[i],
              focused: (start + i) == _librarySelected,
              onSelect: () => setState(() => _librarySelected = start + i),
            ),
          ),
          if (i < visible.length - 1) const SizedBox(width: 24),
        ],
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, {VoidCallback? onTap}) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: TvColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TvColors.textSecondary),
      ),
      child: Row(
        children: [
          Icon(icon, color: TvColors.neonGreen, size: 40),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFontsStyle.spaceGrotesk(
                  36,
                  bold: true,
                  color: TvColors.neonGreen,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: TvColors.textSecondary,
                  fontSize: 18,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return FocusableActionDetector(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<Intent>(onInvoke: (_) {
          onTap();
          return null;
        }),
      },
      child: InkWell(
        onTap: onTap,
        child: content,
      ),
    );
  }

  // ---------------- Perfil ----------------

  Widget _buildProfile() {
    final user = ApiService.currentUser;
    if (user == null) return _buildLoginRequired('PERFIL');
    return _buildTabShell([
      _buildTabTitle('PERFIL'),
      const SizedBox(height: 40),
      Row(
        children: [
          const Icon(Icons.account_circle, color: TvColors.neonGreen, size: 120),
          const SizedBox(width: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.gamertag.isNotEmpty ? user.gamertag : user.username,
                style: GoogleFontsStyle.spaceGrotesk(48, bold: true),
              ),
              const SizedBox(height: 8),
              Text(
                user.email,
                style: const TextStyle(color: TvColors.textSecondary, fontSize: 24),
              ),
              const SizedBox(height: 8),
              Text(
                'Nivel ${user.level} · ${user.xp} XP · ${user.gamesOwned} juegos',
                style: const TextStyle(color: TvColors.neonGreen, fontSize: 24),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 48),
      _buildProfileButton(
        0,
        Icons.edit_outlined,
        'EDITAR PERFIL',
        'Cambia tu gamertag, username y email',
      ),
      const SizedBox(height: 24),
      _buildProfileButton(
        1,
        Icons.logout,
        'CERRAR SESIÓN',
        'Cierra la sesión en esta TV',
      ),
    ]);
  }

  Widget _buildProfileButton(
    int index,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final focused = _profileSelected == index;
    return InkWell(
      onTap: () {
        setState(() => _profileSelected = index);
        if (index == 0) {
          _openEditProfile();
        } else {
          _logout();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        decoration: BoxDecoration(
          color: focused
              ? TvColors.neonGreen.withValues(alpha: 0.12)
              : TvColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: focused ? TvColors.gold : TvColors.textSecondary,
            width: focused ? 4 : 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: focused ? TvColors.gold : TvColors.neonGreen, size: 48),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFontsStyle.spaceGrotesk(32, bold: true)),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: TvColors.textSecondary, fontSize: 24),
                  ),
                ],
              ),
            ),
            if (focused)
              const Icon(Icons.check_circle, color: TvColors.gold, size: 32),
          ],
        ),
      ),
    );
  }

  /// Mensaje común cuando la pestaña requiere sesión (SA.2.A).
  Widget _buildLoginRequired(String title) {
    return _buildTabShell([
      _buildTabTitle(title),
      Expanded(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, color: TvColors.textSecondary, size: 96),
              const SizedBox(height: 24),
              Text(
                'Necesitas iniciar sesión',
                style: GoogleFontsStyle.spaceGrotesk(40, bold: true),
              ),
              const SizedBox(height: 8),
              const Text(
                'para acceder a este apartado',
                style: TextStyle(color: TvColors.textSecondary, fontSize: 28),
              ),
            ],
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Center(
          child: ElevatedButton(
            onPressed: _startLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: TvColors.neonGreen,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'INICIAR SESIÓN',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    ]);
  }

  // ---------------- Configuración ----------------

  Widget _buildSettings() {
    return _buildTabShell([
      _buildTabTitle('CONFIGURACIÓN'),
      const SizedBox(height: 8),
      const Text(
        'Usa ↑ ↓ para navegar y Enter para cambiar',
        style: TextStyle(color: TvColors.textSecondary, fontSize: 24),
      ),
      const SizedBox(height: 40),
      _buildSettingRow(
        0,
        Icons.notifications_outlined,
        'Notificaciones',
        'Avisos de ofertas y lanzamientos',
        _notificationsEnabled,
      ),
      const SizedBox(height: 24),
      _buildSettingRow(
        1,
        Icons.energy_savings_leaf_outlined,
        'Ahorro de energía',
        'Atenúa la interfaz tras 5 minutos',
        _powerSaveEnabled,
      ),
    ]);
  }

  Widget _buildSettingRow(
    int index,
    IconData icon,
    String title,
    String subtitle,
    bool value,
  ) {
    final focused = _settingsSelected == index;
    return InkWell(
      onTap: () {
        setState(() {
          _settingsSelected = index;
          _toggleSetting();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        decoration: BoxDecoration(
          color: focused
              ? TvColors.neonGreen.withValues(alpha: 0.10)
              : TvColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: focused ? TvColors.gold : TvColors.textSecondary,
            width: focused ? 4 : 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: focused ? TvColors.gold : TvColors.neonGreen, size: 48),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFontsStyle.spaceGrotesk(32, bold: true)),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: TvColors.textSecondary, fontSize: 24),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Container(
              width: 96,
              height: 48,
              decoration: BoxDecoration(
                color: value ? TvColors.neonGreen : TvColors.textSecondary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  value ? 'ON' : 'OFF',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Dashboard (existente) ----------------

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

  /// Rail horizontal de juegos (SA.2.B): muestra hasta [_railVisible] tarjetas
  /// y la selección desplaza la ventana para alcanzar todo el catálogo.
  Widget _buildRail() {
    final games = _games;
    if (games.isEmpty) return const SizedBox.shrink();

    final maxStart =
        games.length > _railVisible ? games.length - _railVisible : 0;
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

/// Fondo del juego seleccionado (SA.2.C / DE.1).
///
/// Base: backdrop HD 1920x1080 (imagen generada en el backend) claveada por
/// [Game.id] para que el cambio de juego sea inmediato y nítido.
/// Overlay: video del juego solo si existe, translúcido para no tapar la imagen.
/// Si la imagen falla, cae al póster original de la API.
class _Background extends StatelessWidget {
  final Game? selected;
  const _Background({required this.selected});

  @override
  Widget build(BuildContext context) {
    if (selected == null) return _fallback();
    // El Stack (y el video) llevan key por juego: cada cambio recrea el
    // subtree completo y evita que el <video> deje su último frame pegado.
    return Stack(
      key: ValueKey('bg-${selected!.id}'),
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
            key: ValueKey(selected!.id),
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
