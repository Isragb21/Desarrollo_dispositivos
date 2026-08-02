import 'package:flutter/material.dart';
import 'package:gamestore_app/theme/app_theme.dart';
import 'package:gamestore_app/services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameCtrl;
  late TextEditingController _gamertagCtrl;
  late TextEditingController _emailCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ApiService.currentUser;
    _usernameCtrl = TextEditingController(text: user?.username ?? '');
    _gamertagCtrl = TextEditingController(text: user?.gamertag ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _gamertagCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final user = await ApiService.updateProfile(
      username: _usernameCtrl.text.trim(),
      gamertag: _gamertagCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (user != null) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiService.lastError ?? "Error al guardar"),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("EDITAR PERFIL")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.person, size: 80, color: AppColors.neonGreen),
                const SizedBox(height: 24),
                _buildField("Username", _usernameCtrl, "Ingresa tu username"),
                const SizedBox(height: 16),
                _buildField("Gamertag", _gamertagCtrl, "Ingresa tu gamertag"),
                const SizedBox(height: 16),
                _buildField("Email", _emailCtrl, "Ingresa tu email",
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.save),
                  label: Text(_saving ? "GUARDANDO..." : "GUARDAR CAMBIOS"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint,
      {TextInputType? keyboardType}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.neonGreen),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.neonGreenDim),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.neonGreenDim),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.neonGreen, width: 2),
        ),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return "$label es requerido";
        return null;
      },
    );
  }
}
