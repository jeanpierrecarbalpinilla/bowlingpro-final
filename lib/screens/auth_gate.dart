import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// Decide automáticamente qué pantalla mostrar según el estado de
/// autenticación de Firebase: si hay una sesión activa, muestra
/// HomeScreen; si no, muestra LoginScreen. Se actualiza solo cuando
/// el usuario inicia o cierra sesión, sin necesidad de navegar
/// manualmente entre pantallas.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
