import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'register_screen.dart'; // Importación para poder navegar al registro

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true; // solo visual: mostrar/ocultar contraseña

  void _login() async {
    setState(() => _isLoading = true);
    var user = await _authService.signInWithEmailPassword(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    setState(() => _isLoading = false);

    if (user != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Inicio de sesión exitoso!')),
      );
      // En la próxima fase, aquí navegaremos a la pantalla principal
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Revisa tus credenciales o conexión.')),
      );
    }
  }

  // Paleta de la marca (la misma del home: azul oscuro, celeste y naranja)
  static const Color _azul = Color(0xFF1E3A5F);
  static const Color _celeste = Color(0xFF29B6F6);
  static const Color _naranja = Color(0xFFF57C00);

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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: Image.asset('assets/logo.png', height: 130)),
                  const SizedBox(height: 28),
                  const Text(
                    'Bienvenido',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: _azul,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Inicia sesión para continuar',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Color(0xFF6B7A8C)),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _emailController,
                    decoration: _decoracion(
                      'Correo electrónico',
                      Icons.mail_outline_rounded,
                    ),
                    keyboardType: TextInputType.emailAddress,
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
                          onPressed: _login,
                          child: const Text(
                            'Iniciar Sesión',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: const Text.rich(
                      TextSpan(
                        text: '¿No tienes cuenta? ',
                        style: TextStyle(color: Color(0xFF6B7A8C), fontSize: 15),
                        children: [
                          TextSpan(
                            text: 'Regístrate aquí',
                            style: TextStyle(
                              color: _naranja,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
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