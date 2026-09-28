import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bowling_pro/services/leccion_service.dart';

class NivelesScreen extends StatelessWidget {
  const NivelesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final leccionService = LeccionService();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    // Niveles definidos para la Épica 2
    final niveles = ['Principiante', 'Intermedio', 'Avanzado'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Niveles de Aprendizaje'),
        backgroundColor: const Color(0xFF1E3A5F),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3A5F), Color(0xFF0D1B2A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: niveles.length,
          itemBuilder: (context, index) {
            final nivel = niveles[index];

            return FutureBuilder<bool>(
              // Lógica de la regla: usar puedeAccederA del servicio
              future: leccionService.puedeAccederA(userId, nivel),
              builder: (context, snapshot) {
                final bool tieneAcceso = snapshot.data ?? false;
                final bool isLoading = snapshot.connectionState == ConnectionState.waiting;

                return Card(
                  color: tieneAcceso ? Colors.white : Colors.white54,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                    leading: Icon(
                      tieneAcceso ? Icons.play_circle_fill : Icons.lock,
                      color: tieneAcceso ? const Color(0xFF29B6F6) : Colors.grey,
                      size: 40,
                    ),
                    title: Text(
                      nivel,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: tieneAcceso ? Colors.black87 : Colors.black38,
                      ),
                    ),
                    subtitle: Text(
                      tieneAcceso ? 'Toca para ver lecciones' : 'Desbloquea el nivel anterior',
                      style: TextStyle(
                        color: tieneAcceso ? Colors.black54 : Colors.black38,
                      ),
                    ),
                    trailing: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.arrow_forward_ios,
                            color: tieneAcceso ? Colors.black54 : Colors.transparent,
                          ),
                    onTap: tieneAcceso
                        ? () {
                            // TODO: Navegar a leccion_detalle_screen.dart
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Próximamente: Lecciones de $nivel')),
                            );
                          }
                        : null, // Si no tiene acceso, el botón queda totalmente deshabilitado
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}