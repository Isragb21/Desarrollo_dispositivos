import 'package:flutter/material.dart';
import 'package:gamestore_app/theme/app_theme.dart';
import 'package:gamestore_app/services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _gamertagController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _gamertagController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final user = await ApiService.register(
      _usernameController.text.trim(),
      _gamertagController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
    );
    setState(() => _loading = false);
    if (!mounted) return;
    if (user != null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Operador registrado correctamente")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiService.lastError ?? "Error al registrar")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("NUEVO OPERADOR")),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.gold, width: 2),
                    ),
                    child: const Icon(
                      Icons.person_add,
                      color: AppColors.gold,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: "NOMBRE DE USUARIO",
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    style: const TextStyle(color: AppColors.textPrimary),
                    validator: (v) =>
                        v == null || v.isEmpty ? "Ingresa tu nombre de usuario" : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _gamertagController,
                    decoration: const InputDecoration(
                      labelText: "GAMERTAG",
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    style: const TextStyle(color: AppColors.textPrimary),
                    validator: (v) =>
                        v == null || v.isEmpty ? "Ingresa tu gamertag" : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: "CORREO DEL OPERADOR",
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    style: const TextStyle(color: AppColors.textPrimary),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Ingresa tu correo";
                      if (!v.contains('@')) return "Correo inválido";
                      return null;
                    },
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
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Ingresa tu protocolo";
                      if (v.length < 6) return "Mínimo 6 caracteres";
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      labelText: "CONFIRMAR PROTOCOLO",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    style: const TextStyle(color: AppColors.textPrimary),
                    validator: (v) {
                      if (v != _passwordController.text) {
                        return "Los protocolos no coinciden";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _register,
                      child: _loading
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text("ACTIVAR OPERADOR"),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
