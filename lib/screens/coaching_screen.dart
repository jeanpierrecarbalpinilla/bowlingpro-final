import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/coaching_service.dart';
import 'detalle_jugador_screen.dart';

/// Vista del entrenador: lista de jugadores de su grupo.
class CoachingScreen extends StatefulWidget {
  const CoachingScreen({super.key});

  @override
  State<CoachingScreen> createState() => _CoachingScreenState();
}

class _CoachingScreenState extends State<CoachingScreen> {
  final CoachingService _service = CoachingService();
  late Future<List<UserModel>> _futuro;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _futuro = uid == null
        ? Future.error('No hay sesión activa')
        : _service.jugadoresDelGrupo(uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Coaching'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3A5F), Color(0xFF0D1B2A)],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<List<UserModel>>(
            future: _futuro,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFFA726)),
                );
              }
              if (snapshot.hasError) {
                return _Mensaje(
                  icono: Icons.error_outline_rounded,
                  titulo: 'No se pudo cargar tu grupo',
                  detalle: '${snapshot.error}'.replaceFirst('Exception: ', ''),
                );
              }

              final jugadores = snapshot.data ?? [];
              if (jugadores.isEmpty) {
                return const _Mensaje(
                  icono: Icons.groups_rounded,
                  titulo: 'Tu grupo aún no tiene jugadores',
                  detalle: 'Cuando un jugador se registre en tu grupo, aparecerá aquí.',
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 56, 16, 24),
                children: [
                  Text(
                    'Jugadores de tu grupo (${jugadores.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...jugadores.map(
                    (j) => _JugadorTile(
                      email: j.email,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetalleJugadorScreen(
                            jugadorUid: j.uid,
                            jugadorEmail: j.email,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _JugadorTile extends StatelessWidget {
  final String email;
  final VoidCallback onTap;

  const _JugadorTile({required this.email, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF29B6F6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: Color(0xFF29B6F6), size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    email,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.35)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Mensaje extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String detalle;

  const _Mensaje({
    required this.icono,
    required this.titulo,
    required this.detalle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 56, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              detalle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}