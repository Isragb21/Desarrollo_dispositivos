import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gamestore_tv/services/api_service.dart';
import 'package:gamestore_tv/theme/tv_theme.dart';

/// Login TV con confirmación 2FA en el wearable (SA.2.A).
///
/// Flujo:
///  1. Email + contraseña -> POST /auth/login-tv (crea solicitud pendiente).
///  2. Polling a /auth/check-2fa/:email cada 2s.
///  3. La app móvil (con wearable conectado) confirma/rechaza en el backend.
///  4. 'confirmed' -> sesión iniciada; 'rejected' -> error visible.
class TvLoginScreen extends StatefulWidget {
  const TvLoginScreen({super.key, this.onBack});

  /// Permite regresar (por ejemplo, a la pantalla de perfil).
  final VoidCallback? onBack;

  @override
  State<TvLoginScreen> createState() => _TvLoginScreenState();
}

enum _LoginStage { idle, submitting, waiting, confirmed, rejected, error }

class _TvLoginScreenState extends State<TvLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _submitFocus = FocusNode();

  _LoginStage _stage = _LoginStage.idle;
  String _message = '';
  String _email = '';
  Timer? _poll;

  @override
  void dispose() {
    _poll?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _submitFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _stage = _LoginStage.error;
        _message = 'Ingresa email y contraseña';
      });
      return;
    }
    setState(() => _stage = _LoginStage.submitting);
    final pending = await ApiService.loginTv(email, password);
    if (!mounted) return;
    if (!pending) {
      setState(() {
        _stage = _LoginStage.error;
        _message = 'Credenciales inválidas o no se pudo iniciar sesión';
      });
      return;
    }
    _email = email;
    setState(() => _stage = _LoginStage.waiting);
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _checkStatus());
  }

  Future<void> _checkStatus() async {
    final status = await ApiService.check2fa(_email);
    if (!mounted) return;
    if (status == 'confirmed') {
      _poll?.cancel();
      setState(() => _stage = _LoginStage.confirmed);
    } else if (status == 'rejected') {
      _poll?.cancel();
      setState(() {
        _stage = _LoginStage.rejected;
        _message = 'Inicio de sesión rechazado en el wearable';
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
        // Enter en el botón o en los campos dispara el login (SA.2.B).
        if (node == _submitFocus ||
            node == _emailFocus ||
            node == _passwordFocus) {
          if (_stage == _LoginStage.idle ||
              _stage == _LoginStage.error ||
              _stage == _LoginStage.rejected) {
            _submit();
          }
        }
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  void _focusNext() {
    if (_emailFocus.hasFocus) {
      _passwordFocus.requestFocus();
    } else if (_passwordFocus.hasFocus) {
      _submitFocus.requestFocus();
    }
  }

  void _focusPrev() {
    if (_passwordFocus.hasFocus) {
      _emailFocus.requestFocus();
    } else if (_submitFocus.hasFocus) {
      _passwordFocus.requestFocus();
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
                      Icons.account_circle,
                      color: TvColors.neonGreen,
                      size: 96,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'INICIAR SESIÓN',
                      textAlign: TextAlign.center,
                      style: GoogleFontsStyle.spaceGrotesk(40, bold: true),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Confirma en tu wearable al terminar',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: TvColors.textSecondary,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildField(
                      _emailFocus,
                      _emailController,
                      'Correo electrónico',
                      Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),
                    _buildField(
                      _passwordFocus,
                      _passwordController,
                      'Contraseña',
                      Icons.lock_outline,
                      obscure: true,
                    ),
                    const SizedBox(height: 40),
                    _buildSubmitButton(),
                    if (_stage != _LoginStage.idle) ...[
                      const SizedBox(height: 32),
                      _buildStatus(),
                    ],
                    if (widget.onBack != null) ...[
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: widget.onBack,
                        child: const Text(
                          'CANCELAR',
                          style: TextStyle(
                            color: TvColors.textSecondary,
                            fontSize: 24,
                            letterSpacing: 2,
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
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return Focus(
      focusNode: focus,
      child: TextField(
        controller: controller,
        obscureText: obscure,
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

  Widget _buildSubmitButton() {
    final busy = _stage == _LoginStage.submitting ||
        _stage == _LoginStage.waiting;
    return Focus(
      focusNode: _submitFocus,
      child: ElevatedButton(
        onPressed: busy ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: TvColors.neonGreen,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 24),
          disabledBackgroundColor: TvColors.textSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: busy
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
                    'ESPERANDO CONFIRMACIÓN...',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            : const Text(
                'INICIAR SESIÓN',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildStatus() {
    switch (_stage) {
      case _LoginStage.confirmed:
        return const _StatusBox(
          icon: Icons.check_circle,
          color: TvColors.neonGreen,
          message: 'SESIÓN INICIADA',
        );
      case _LoginStage.rejected:
      case _LoginStage.error:
        return _StatusBox(
          icon: Icons.error_outline,
          color: TvColors.error,
          message: _message,
        );
      default:
        return const _StatusBox(
          icon: Icons.watch_outlined,
          color: TvColors.gold,
          message: 'Esperando confirmación en tu wearable...',
        );
    }
  }
}

class _StatusBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;

  const _StatusBox({
    required this.icon,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

/// Estilos de texto reutilizables (mismo estilo que TvHomeScreen).
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
