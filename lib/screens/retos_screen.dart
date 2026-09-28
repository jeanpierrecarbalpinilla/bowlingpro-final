import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/insignia_service.dart';

/// Pantalla de retos e insignias del jugador.
class RetosScreen extends StatefulWidget {
  const RetosScreen({super.key});

  @override
  State<RetosScreen> createState() => _RetosScreenState();
}

class _RetosScreenState extends State<RetosScreen> {
  final InsigniaService _service = InsigniaService();

  bool _cargando = true;
  String? _error;
  bool _desbloqueada = false;
  int _strikes = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _error = 'No hay sesion activa';
        _cargando = false;
      });
      return;
    }
    try {
      // Valida contra el historial y desbloquea si corresponde.
      await _service.evaluar(uid);
      final tiene = await _service.obtenerDesbloqueadas(uid);
      final strikes = await _service.totalStrikes(uid);
      if (!mounted) return;
      setState(() {
        _desbloqueada = tiene.contains(primerStrike.id);
        _strikes = strikes;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e'.replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Retos e insignias'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3A5F), Color(0xFF0D1B2A)],
          ),
        ),
        child: SafeArea(child: _contenido()),
      ),
    );
  }

  Widget _contenido() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFA726)),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 56, 16, 24),
      children: [
        const Text(
          'Tus insignias',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        _InsigniaCard(
          insignia: primerStrike,
          desbloqueada: _desbloqueada,
          progreso: _desbloqueada
              ? 'Strikes en tu historial: $_strikes'
              : 'Registra una partida con al menos un strike para desbloquearla.',
        ),
      ],
    );
  }
}

class _InsigniaCard extends StatelessWidget {
  final Insignia insignia;
  final bool desbloqueada;
  final String progreso;

  const _InsigniaCard({
    required this.insignia,
    required this.desbloqueada,
    required this.progreso,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        desbloqueada ? const Color(0xFFFFA726) : Colors.white.withValues(alpha: 0.35);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: desbloqueada
              ? const Color(0xFFFFA726).withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              desbloqueada ? Icons.emoji_events_rounded : Icons.lock_rounded,
              color: color,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insignia.titulo,
                  style: TextStyle(
                    color: Colors.white
                        .withValues(alpha: desbloqueada ? 1 : 0.6),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  insignia.descripcion,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  progreso,
                  style: TextStyle(
                    color: desbloqueada
                        ? const Color(0xFF66BB6A)
                        : Colors.white.withValues(alpha: 0.45),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}