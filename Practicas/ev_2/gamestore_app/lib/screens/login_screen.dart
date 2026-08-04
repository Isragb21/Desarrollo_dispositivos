import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gamestore_app/theme/app_theme.dart';
import 'package:gamestore_app/services/api_service.dart';
import 'package:gamestore_app/screens/register_screen.dart';
import 'package:gamestore_app/screens/home_screen.dart';
import 'package:gamestore_app/providers/wearable_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final user = await ApiService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    setState(() => _loading = false);
    if (!mounted) return;
    if (user != null) {
      // Notifica al wearable el intento de inicio de sesión (2FA).
      context.read<WearableProvider>().sendSessionAlert(
            _emailController.text.trim(),
          );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiService.lastError ?? "Credenciales inválidas")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 12),
                  Text(
                    "GAMESTORE",
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.neonGreen,
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "ACCESO DE OPERADOR",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.gold,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: "CORREO DEL OPERADOR",
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    style: const TextStyle(color: AppColors.textPrimary),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        v == null || v.isEmpty ? "Ingresa tu correo" : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: "PROTOCOLO DE ACCESO",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    style: const TextStyle(color: AppColors.textPrimary),
                    validator: (v) =>
                        v == null || v.isEmpty ? "Ingresa tu protocolo" : null,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text("INGRESAR"),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: Text(
                      "REGISTRAR NUEVO OPERADOR",
                      style: TextStyle(
                        color: AppColors.gold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.neonGreen, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonGreen.withValues(alpha: 0.3),
            blurRadius: 20,
          ),
        ],
      ),
      child: const Icon(
        Icons.sports_esports,
        size: 40,
        color: AppColors.neonGreen,
      ),
    );
  }
}
