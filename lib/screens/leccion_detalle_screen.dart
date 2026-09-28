import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bowling_pro/screens/evaluacion_screen.dart';

class LeccionDetalleScreen extends StatelessWidget {
  final String nivel;

  const LeccionDetalleScreen({super.key, required this.nivel});

  // Videos reales de YouTube para esta lección.
  static const List<Map<String, String>> _videos = [
    {
      'titulo': 'Cómo lanzar',
      'url': 'https://www.youtube.com/watch?v=k3_4Zbb2oE4',
    },
    {
      'titulo': 'Los pasos básicos en el approach para jugar al bowling',
      'url': 'https://www.youtube.com/watch?v=2wBoWkAt2as',
    },
    {
      'titulo': 'Bolos: Desarrollando la técnica de lanzamiento',
      'url': 'https://www.youtube.com/watch?v=ZTBes7Om3Eg',
    },
  ];

  Future<void> _abrirVideo(BuildContext context, String url) async {
    bool ok = false;
    try {
      ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      ok = false;
    }
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el video')),
      );
    }
  }

  Widget _tarjetaVideo(BuildContext context, String titulo, String url) {
    final videoId = Uri.parse(url).queryParameters['v'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: () => _abrirVideo(context, url),
        child: Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(15.0),
            border: Border.all(color: const Color(0xFF29B6F6), width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13.0),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (videoId != null)
                  Image.network(
                    'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                Container(color: Colors.black38),
                const Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: Text(
                    titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lección: $nivel'),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Videos reales de YouTube (al tocar se abre el video)
              ..._videos.map(
                (v) => _tarjetaVideo(context, v['titulo']!, v['url']!),
              ),
              const SizedBox(height: 24),
              const Text(
                'Fundamentos y Postura',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '1. Mantén la espalda recta y las rodillas ligeramente flexionadas.\n'
                '2. Sostén la bola a la altura del pecho.\n'
                '3. Da cuatro pasos fluidos hacia la línea de falta.\n'
                '4. Mantén el brazo firme durante el balanceo.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA726), // Naranja de acento
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  onPressed: () {
                    // Navegación real conectada a la pantalla de evaluación
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EvaluacionScreen(nivel: nivel),
                      ),
                    );
                  },
                  child: const Text(
                    'Hacer Evaluación',
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