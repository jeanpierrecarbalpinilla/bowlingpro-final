import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/partida_service.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final PartidaService _service = PartidaService();
  late Future<List<Map<String, dynamic>>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  Future<List<Map<String, dynamic>>> _cargar() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Future.value([]);
    return _service.obtenerPartidas(uid);
  }

  Future<void> _refrescar() async {
    final nuevo = _cargar();
    setState(() => _futuro = nuevo);
    await nuevo;
  }

  String _fecha(dynamic valor) {
    if (valor is! Timestamp) return '-';
    final d = valor.toDate();
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}  $hh:$mi';
  }

  int _num(dynamic v) => v is num ? v.toInt() : 0;

  /// Calcula promedio, mejor puntaje, % de strikes y % de spares.
  /// % strikes = frames con strike en el primer lanzamiento / frames jugados.
  /// % spares = spares / frames donde el spare era posible (sin strike).
  Map<String, double> _estadisticas(List<Map<String, dynamic>> partidas) {
    if (partidas.isEmpty) {
      return {'promedio': 0, 'mejor': 0, 'strikes': 0, 'spares': 0};
    }

    int suma = 0;
    int mejor = 0;
    int framesTotal = 0;
    int framesStrike = 0;
    int framesSpare = 0;

    for (final p in partidas) {
      final puntaje = _num(p['puntajeTotal']);
      suma += puntaje;
      if (puntaje > mejor) mejor = puntaje;

      final frames = (p['frames'] as List?) ?? [];
      for (final f in frames) {
        final l = List<int>.from(((f as Map)['lanzamientos'] as List)
            .map((e) => (e as num).toInt()));
        if (l.isEmpty) continue;
        framesTotal++;
        if (l[0] == 10) {
          framesStrike++;
        } else if (l.length >= 2 && l[0] + l[1] == 10) {
          framesSpare++;
        }
      }
    }

    final sinStrike = framesTotal - framesStrike;
    return {
      'promedio': suma / partidas.length,
      'mejor': mejor.toDouble(),
      'strikes': framesTotal == 0 ? 0 : framesStrike * 100 / framesTotal,
      'spares': sinStrike == 0 ? 0 : framesSpare * 100 / sinStrike,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Historial y estadísticas'),
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
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _futuro,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFFA726)),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No se pudo cargar el historial:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                );
              }

              final partidas = snapshot.data ?? [];
              if (partidas.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sports_baseball_rounded,
                          size: 56,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Aún no tienes partidas guardadas',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Juega una en "Registrar partida" y aparecerá aquí.',
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

              final est = _estadisticas(partidas);

              return RefreshIndicator(
                onRefresh: _refrescar,
                color: const Color(0xFFFFA726),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 56, 16, 24),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            titulo: 'Promedio',
                            valor: est['promedio']!.toStringAsFixed(1),
                            color: const Color(0xFFFFA726),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            titulo: 'Mejor',
                            valor: est['mejor']!.toInt().toString(),
                            color: const Color(0xFF66BB6A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            titulo: '% Strikes',
                            valor: '${est['strikes']!.toStringAsFixed(0)}%',
                            color: const Color(0xFF29B6F6),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            titulo: '% Spares',
                            valor: '${est['spares']!.toStringAsFixed(0)}%',
                            color: const Color(0xFF29B6F6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Partidas (${partidas.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...partidas.map(
                      (p) => _PartidaTile(
                        fecha: _fecha(p['fecha']),
                        puntaje: _num(p['puntajeTotal']),
                        strikes: _num(p['strikes']),
                        spares: _num(p['spares']),
                        pines: _num(p['pinesDerribados']),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de una estadística individual.
class _StatCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color color;

  const _StatCard({
    required this.titulo,
    required this.valor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de una partida guardada.
class _PartidaTile extends StatelessWidget {
  final String fecha;
  final int puntaje;
  final int strikes;
  final int spares;
  final int pines;

  const _PartidaTile({
    required this.fecha,
    required this.puntaje,
    required this.strikes,
    required this.spares,
    required this.pines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFA726).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '$puntaje',
              style: const TextStyle(
                color: Color(0xFFFFA726),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fecha,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$strikes strikes · $spares spares · $pines pines',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 13,
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