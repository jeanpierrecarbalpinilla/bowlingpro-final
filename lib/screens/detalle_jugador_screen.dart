import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/coaching_service.dart';

/// Detalle de un jugador: estadísticas, últimas partidas y comentarios
/// del entrenador.
class DetalleJugadorScreen extends StatefulWidget {
  final String jugadorUid;
  final String jugadorEmail;

  const DetalleJugadorScreen({
    super.key,
    required this.jugadorUid,
    required this.jugadorEmail,
  });

  @override
  State<DetalleJugadorScreen> createState() => _DetalleJugadorScreenState();
}

class _DetalleJugadorScreenState extends State<DetalleJugadorScreen> {
  final CoachingService _service = CoachingService();
  final TextEditingController _controller = TextEditingController();

  bool _cargando = true;
  bool _enviando = false;
  String? _error;
  List<Map<String, dynamic>> _partidas = [];
  List<Map<String, dynamic>> _comentarios = [];

  String get _entrenadorUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final partidas =
          await _service.partidasDeJugador(_entrenadorUid, widget.jugadorUid);
      final comentarios = await _service.obtenerComentarios(widget.jugadorUid);
      if (!mounted) return;
      setState(() {
        _partidas = partidas;
        _comentarios = comentarios;
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

  Future<void> _enviar() async {
    setState(() => _enviando = true);
    try {
      await _service.guardarComentario(
        entrenadorUid: _entrenadorUid,
        jugadorUid: widget.jugadorUid,
        texto: _controller.text,
      );
      _controller.clear();
      final comentarios = await _service.obtenerComentarios(widget.jugadorUid);
      if (!mounted) return;
      setState(() => _comentarios = comentarios);
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $e')),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  int _num(dynamic v) => v is num ? v.toInt() : 0;

  String _fecha(dynamic valor) {
    if (valor is! Timestamp) return '-';
    final d = valor.toDate();
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}  $hh:$mi';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(widget.jugadorEmail, style: const TextStyle(fontSize: 16)),
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

    final total = _partidas.length;
    final suma = _partidas.fold<int>(0, (a, p) => a + _num(p['puntajeTotal']));
    final mejor = _partidas.fold<int>(
        0, (a, p) => _num(p['puntajeTotal']) > a ? _num(p['puntajeTotal']) : a);
    final promedio = total == 0 ? 0.0 : suma / total;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 56, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: _Stat(
                  titulo: 'Partidas',
                  valor: '$total',
                  color: const Color(0xFF29B6F6)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Stat(
                  titulo: 'Promedio',
                  valor: promedio.toStringAsFixed(1),
                  color: const Color(0xFFFFA726)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Stat(
                  titulo: 'Mejor',
                  valor: '$mejor',
                  color: const Color(0xFF66BB6A)),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const _Titulo('Últimas partidas'),
        if (_partidas.isEmpty)
          const _Vacio('Este jugador aún no tiene partidas guardadas.')
        else
          ..._partidas.take(5).map(
                (p) => _Fila(
                  principal: '${_num(p['puntajeTotal'])} pts',
                  secundario:
                      '${_fecha(p['fecha'])}  ·  ${_num(p['strikes'])} strikes · ${_num(p['spares'])} spares',
                  color: const Color(0xFFFFA726),
                ),
              ),
        const SizedBox(height: 22),
        const _Titulo('Comentarios del entrenador'),
        TextField(
          controller: _controller,
          minLines: 2,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Escribe una recomendación o comentario de sesión...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFFFA726)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: _enviando ? null : _enviar,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF66BB6A),
              foregroundColor: const Color(0xFF0D1B2A),
            ),
            child: _enviando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar comentario'),
          ),
        ),
        const SizedBox(height: 16),
        if (_comentarios.isEmpty)
          const _Vacio('Aún no hay comentarios para este jugador.')
        else
          ..._comentarios.map(
            (c) => _Fila(
              principal: '${c['texto']}',
              secundario: _fecha(c['fecha']),
              color: const Color(0xFF29B6F6),
            ),
          ),
      ],
    );
  }
}

class _Titulo extends StatelessWidget {
  final String texto;
  const _Titulo(this.texto);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          texto,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

class _Vacio extends StatelessWidget {
  final String texto;
  const _Vacio(this.texto);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          texto,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 13,
          ),
        ),
      );
}

class _Stat extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color color;

  const _Stat({
    required this.titulo,
    required this.valor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final String principal;
  final String secundario;
  final Color color;

  const _Fila({
    required this.principal,
    required this.secundario,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border(
          left: BorderSide(color: color, width: 3),
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          right: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            principal,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            secundario,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}