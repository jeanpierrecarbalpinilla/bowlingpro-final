import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/frame.dart';
import '../models/partida.dart';
import '../services/partida_service.dart';

class NuevaPartidaScreen extends StatefulWidget {
  const NuevaPartidaScreen({super.key});

  @override
  State<NuevaPartidaScreen> createState() => _NuevaPartidaScreenState();
}

class _NuevaPartidaScreenState extends State<NuevaPartidaScreen> {
  Partida _partida = Partida();
  final PartidaService _service = PartidaService();
  bool _guardando = false;

  // Índice del frame que espera lanzamientos; -1 si ya están los 10 completos.
  int get _frameActual => _partida.frames.indexWhere((f) => !f.completo);
  bool get _completa => _frameActual == -1;

  int get _maxPines => _completa ? 0 : pinesEnPie(_partida.frames[_frameActual]);

  /// Puntaje acumulado por frame; null mientras el frame no pueda
  /// puntuarse (bloqueo circular: faltan lanzamientos bonus).
  List<int?> _acumulados() {
    final resultado = <int?>[];
    int total = 0;
    bool corte = false;
    for (final f in _partida.frames) {
      if (!corte && f.cerrado) {
        total += _partida.puntajeFrame(f.numero);
        resultado.add(total);
      } else {
        corte = true;
        resultado.add(null);
      }
    }
    return resultado;
  }

  void _registrar(int pines) {
    try {
      setState(() => _partida.registrarLanzamiento(pines));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo registrar: $e')),
      );
    }
  }

  Future<void> _guardar() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _guardando = true);
    try {
      await _service.guardarPartida(uid, _partida);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Partida guardada')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final acumulados = _acumulados();
    final parcial = acumulados.lastWhere((a) => a != null, orElse: () => 0) ?? 0;
    final actual = _frameActual;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Nueva partida'),
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Text(
                  _completa ? 'Puntaje final' : 'Puntaje actual',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
                Text(
                  '$parcial',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 104,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 10,
                    itemBuilder: (context, i) => _FrameBox(
                      frame: _partida.frames[i],
                      acumulado: acumulados[i],
                      activo: i == actual,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _completa
                      ? 'Partida completa'
                      : 'Frame ${actual + 1}: ¿cuántos pines derribaste?',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: List.generate(11, (n) {
                    final habilitado = !_completa && n <= _maxPines;
                    return SizedBox(
                      width: 64,
                      height: 52,
                      child: FilledButton(
                        onPressed: habilitado ? () => _registrar(n) : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFFA726),
                          foregroundColor: const Color(0xFF0D1B2A),
                          disabledBackgroundColor:
                              Colors.white.withValues(alpha: 0.08),
                          disabledForegroundColor:
                              Colors.white.withValues(alpha: 0.25),
                        ),
                        child: Text(
                          '$n',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _guardando
                            ? null
                            : () => setState(() => _partida = Partida()),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Reiniciar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed:
                            (_completa && !_guardando) ? _guardar : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF66BB6A),
                          foregroundColor: const Color(0xFF0D1B2A),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _guardando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Guardar partida'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Casilla de un frame: número, símbolos de lanzamientos y acumulado.
class _FrameBox extends StatelessWidget {
  final Frame frame;
  final int? acumulado;
  final bool activo;

  const _FrameBox({
    required this.frame,
    required this.acumulado,
    required this.activo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: frame.esFrame10 ? 96 : 66,
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: activo
              ? const Color(0xFFFFA726)
              : Colors.white.withValues(alpha: 0.12),
          width: activo ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${frame.numero}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          Text(
            simbolosDeFrame(frame).join('  '),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            acumulado?.toString() ?? '',
            style: const TextStyle(
              color: Color(0xFF29B6F6),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}