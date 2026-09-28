import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'jugador'; // Rol por defecto
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true; // solo visual: mostrar/ocultar contraseña

  void _register() async {
    setState(() => _isLoading = true);
    var user = await _authService.signUpWithEmailPassword(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _selectedRole,
    );
    setState(() => _isLoading = false);

    if (user != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Cuenta creada con éxito!')),
      );
      Navigator.pop(context); // Regresa al login
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al crear la cuenta.')),
      );
    }
  }

  // Paleta de la marca (la misma del home: azul oscuro, celeste y naranja)
  static const Color _azul = Color(0xFF1E3A5F);
  static const Color _celeste = Color(0xFF29B6F6);

  InputDecoration _decoracion(String label, IconData icono, {Widget? sufijo}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icono, color: _azul),
      suffixIcon: sufijo,
      filled: true,
      fillColor: const Color(0xFFF4F7FB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      floatingLabelStyle: const TextStyle(color: _azul),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE1E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _celeste, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        backgroundColor: Colors.white,
        foregroundColor: _azul,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: Image.asset('assets/logo.png', height: 96)),
                  const SizedBox(height: 20),
                  const Text(
                    'Únete a BowlingPro',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _azul,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Crea tu cuenta y elige tu rol',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Color(0xFF6B7A8C)),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _emailController,
                    decoration: _decoracion(
                      'Correo electrónico',
                      Icons.mail_outline_rounded,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: _decoracion(
                      'Contraseña',
                      Icons.lock_outline_rounded,
                      sufijo: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF6B7A8C),
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    obscureText: _obscurePassword,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: _decoracion('Rol', Icons.badge_outlined),
                    borderRadius: BorderRadius.circular(14),
                    items: ['jugador', 'entrenador', 'administrador']
                        .map((role) => DropdownMenuItem(value: role, child: Text(role.toUpperCase())))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedRole = value!),
                  ),
                  const SizedBox(height: 28),
                  _isLoading
                      ? const SizedBox(
                          height: 54,
                          child: Center(
                            child: CircularProgressIndicator(color: _azul),
                          ),
                        )
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _azul,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 54),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _register,
                          child: const Text(
                            'Registrarse',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
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
}