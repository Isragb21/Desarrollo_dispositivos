import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gamestore_tv/services/api_service.dart';
import 'package:gamestore_tv/theme/tv_theme.dart';

/// Edición del perfil (gamertag, username, email) desde la TV (SA.2.A).
/// Navegación D-pad: ↑ ↓ cambian de campo, Enter guarda, se puede cancelar.
class TvProfileEditScreen extends StatefulWidget {
  const TvProfileEditScreen({super.key, this.onBack});

  /// Permite regresar (por ejemplo, a la pantalla de perfil).
  final VoidCallback? onBack;

  @override
  State<TvProfileEditScreen> createState() => _TvProfileEditScreenState();
}

class _TvProfileEditScreenState extends State<TvProfileEditScreen> {
  final _gamertagController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _gamertagFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _saveFocus = FocusNode();
  final _cancelFocus = FocusNode();

  bool _saving = false;
  bool _error = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    final user = ApiService.currentUser;
    if (user != null) {
      _gamertagController.text = user.gamertag;
      _usernameController.text = user.username;
      _emailController.text = user.email;
    }
  }

  @override
  void dispose() {
    _gamertagController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _gamertagFocus.dispose();
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _saveFocus.dispose();
    _cancelFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = ApiService.currentUser;
    final gamertag = _gamertagController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    if (user == null) {
      Navigator.of(context).pop();
      return;
    }
    if (gamertag.isEmpty || username.isEmpty || email.isEmpty) {
      setState(() {
        _error = true;
        _message = 'Ningún campo puede quedar vacío';
      });
      return;
    }
    setState(() {
      _saving = true;
      _error = false;
      _message = '';
    });
    final updated = await ApiService.updateProfile(
      id: user.id,
      gamertag: gamertag,
      username: username,
      email: email,
    );
    if (!mounted) return;
    if (updated != null) {
      ApiService.currentUser = updated;
      ApiService.saveSession();
      Navigator.of(context).pop(updated);
    } else {
      setState(() {
        _saving = false;
        _error = true;
        _message = 'No se pudo guardar. Verifica que los datos no estén en uso.';
      });
    }
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        _focusNext();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        _focusPrev();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.select:
        if (_saving) return KeyEventResult.handled;
        if (node == _saveFocus) {
          _save();
        } else if (node == _cancelFocus) {
          Navigator.of(context).pop();
        } else {
          _save();
        }
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  void _focusNext() {
    if (_gamertagFocus.hasFocus) {
      _usernameFocus.requestFocus();
    } else if (_usernameFocus.hasFocus) {
      _emailFocus.requestFocus();
    } else if (_emailFocus.hasFocus) {
      _saveFocus.requestFocus();
    } else if (_saveFocus.hasFocus) {
      _cancelFocus.requestFocus();
    }
  }

  void _focusPrev() {
    if (_usernameFocus.hasFocus) {
      _gamertagFocus.requestFocus();
    } else if (_emailFocus.hasFocus) {
      _usernameFocus.requestFocus();
    } else if (_saveFocus.hasFocus) {
      _emailFocus.requestFocus();
    } else if (_cancelFocus.hasFocus) {
      _saveFocus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      child: Scaffold(
        backgroundColor: TvColors.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                width: 760,
                padding: const EdgeInsets.all(64),
                decoration: BoxDecoration(
                  color: TvColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: TvColors.textSecondary, width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.edit_outlined,
                      color: TvColors.neonGreen,
                      size: 96,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'EDITAR PERFIL',
                      textAlign: TextAlign.center,
                      style: GoogleFontsStyle.spaceGrotesk(40, bold: true),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cambia tu gamertag, username o email',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: TvColors.textSecondary,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildField(
                      _gamertagFocus,
                      _gamertagController,
                      'Gamertag',
                      Icons.videogame_asset_outlined,
                    ),
                    const SizedBox(height: 24),
                    _buildField(
                      _usernameFocus,
                      _usernameController,
                      'Username',
                      Icons.person_outline,
                    ),
                    const SizedBox(height: 24),
                    _buildField(
                      _emailFocus,
                      _emailController,
                      'Correo electrónico',
                      Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 40),
                    _buildSaveButton(),
                    const SizedBox(height: 16),
                    _buildCancelButton(),
                    if (_error) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: TvColors.error.withValues(alpha: 0.12),
                          border: Border.all(color: TvColors.error),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: TvColors.error,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    FocusNode focus,
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return Focus(
      focusNode: focus,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: TvColors.textPrimary, fontSize: 28),
        cursorColor: TvColors.neonGreen,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: TvColors.textSecondary,
            fontSize: 24,
          ),
          prefixIcon: Icon(icon, color: TvColors.neonGreen, size: 28),
          filled: true,
          fillColor: TvColors.background,
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
    );
  }

  Widget _buildSaveButton() {
    return Focus(
      focusNode: _saveFocus,
      child: ElevatedButton(
        onPressed: _saving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: TvColors.neonGreen,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 24),
          disabledBackgroundColor: TvColors.textSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _saving
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: 16),
                  Text(
                    'GUARDANDO...',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            : const Text(
                'GUARDAR',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return Focus(
      focusNode: _cancelFocus,
      child: OutlinedButton(
        onPressed: _saving ? null : () => Navigator.of(context).pop(),
        style: OutlinedButton.styleFrom(
          foregroundColor: TvColors.textSecondary,
          padding: const EdgeInsets.symmetric(vertical: 20),
          side: const BorderSide(color: TvColors.textSecondary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'CANCELAR',
          style: TextStyle(fontSize: 28, letterSpacing: 2),
        ),
      ),
    );
  }
}
