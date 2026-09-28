import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bowling_pro/services/leccion_service.dart';

class EvaluacionScreen extends StatefulWidget {
  final String nivel;

  const EvaluacionScreen({super.key, required this.nivel});

  @override
  State<EvaluacionScreen> createState() => _EvaluacionScreenState();
}

class _EvaluacionScreenState extends State<EvaluacionScreen> {
  String? _respuestaSeleccionada;
  bool _guardando = false;

  // Pregunta y opciones (Mock según requerimientos de la Épica 2)
  final String _pregunta = '¿Cuál es la postura correcta antes del lanzamiento?';
  final List<String> _opciones = [
    'Mantener la espalda recta y rodillas flexionadas.',
    'Lanzar la bola lo más fuerte posible sin apuntar.',
    'Soltar la bola con ambas manos al mismo tiempo.',
  ];

  Future<void> _enviarEvaluacion() async {
    if (_respuestaSeleccionada == null) return;

    setState(() => _guardando = true);

    // Lógica simple de aprobación: la opción 0 es la correcta
    if (_respuestaSeleccionada == _opciones[0]) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        // Registra el nivel como completado (esto desbloquea el siguiente)
        await LeccionService().registrarProgreso(userId, widget.nivel);
      }

      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 30),
              SizedBox(width: 10),
              Text('¡Aprobado!'),
            ],
          ),
          content: const Text('Has completado la lección. El siguiente nivel está desbloqueado.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cierra el popup
                Navigator.pop(context); // Cierra la evaluación
                Navigator.pop(context); // Cierra el detalle y vuelve a Niveles
              },
              child: const Text('Continuar', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      );
    } else {
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Respuesta incorrecta. Revisa la lección e intenta de nuevo.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Evaluación: ${widget.nivel}'),
        backgroundColor: const Color(0xFF1E3A5F),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3A5F), Color(0xFF0D1B2A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _pregunta,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              ..._opciones.map((opcion) {
                return Card(
                  color: Colors.white.withOpacity(0.9),
                  margin: const EdgeInsets.only(bottom: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: RadioListTile<String>(
                    title: Text(
                      opcion,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    value: opcion,
                    groupValue: _respuestaSeleccionada,
                    activeColor: const Color(0xFF29B6F6),
                    onChanged: (String? value) {
                      setState(() {
                        _respuestaSeleccionada = value;
                      });
                    },
                  ),
                );
              }),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF66BB6A), // Verde de éxito
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  onPressed: (_respuestaSeleccionada != null && !_guardando)
                      ? _enviarEvaluacion
                      : null,
                  child: _guardando
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                        )
                      : const Text(
                          'Enviar Respuesta',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}