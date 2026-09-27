import 'frame.dart';

/// Excepción lanzada cuando se intenta registrar un lanzamiento
/// sobre una partida que ya terminó sus 10 frames.
class PartidaTerminadaException implements Exception {
  final String message;
  PartidaTerminadaException(this.message);
  @override
  String toString() => message;
}

/// Motor de puntuación oficial de bowling.
///
/// Reglas implementadas:
/// - Puntaje máximo del juego: 300 (12 strikes consecutivos).
/// - Strike: 10 + los dos lanzamientos siguientes (aunque pertenezcan
///   al frame siguiente o al frame 10).
/// - Spare: 10 + el lanzamiento inmediatamente siguiente.
/// - Frame 10: caso especial, admite hasta 3 lanzamientos si hay
///   strike o spare.
/// - Bloqueo circular: un frame nunca se marca [cerrado] (y por lo
///   tanto no se suma a puntajeTotal) hasta que existan los
///   lanzamientos bonus de los que depende.
class Partida {
  final List<Frame> frames = List.generate(10, (i) => Frame(i + 1));
  final List<int> _todosLosLanzamientos = [];
  int _frameActual = 0;

  /// Registra un lanzamiento (pines derribados, 0-10) en el frame
  /// actual, avanzando de frame automáticamente cuando corresponde.
  void registrarLanzamiento(int pines) {
    if (pines < 0 || pines > 10) {
      throw ArgumentError('Un lanzamiento debe derribar entre 0 y 10 pines');
    }
    if (_frameActual >= 10) {
      throw PartidaTerminadaException('La partida ya tiene sus 10 frames completos');
    }

    final frame = frames[_frameActual];

    // Validación básica: no se pueden derribar más pines de los que
    // quedan en pie dentro del mismo frame (excepto frame 10, donde
    // los pines se reponen tras un strike o spare).
    if (!frame.esFrame10 && frame.lanzamientos.isNotEmpty) {
      final derribadosPrevios = frame.lanzamientos[0];
      if (derribadosPrevios + pines > 10) {
        throw ArgumentError('La suma de lanzamientos del frame no puede superar 10 pines');
      }
    }

    frame.lanzamientos.add(pines);
    _todosLosLanzamientos.add(pines);

    if (frame.completo) {
      _frameActual++;
    }

    _actualizarFramesCerrados();
  }

  /// Recorre los frames y marca como [cerrado] aquellos cuyos
  /// lanzamientos bonus (si necesitan alguno) ya están disponibles.
  /// Esta es la implementación concreta del "bloqueo circular".
  void _actualizarFramesCerrados() {
    for (var i = 0; i < frames.length; i++) {
      final frame = frames[i];
      if (frame.cerrado || !frame.completo) continue;

      if (frame.esFrame10) {
        frame.cerrado = true; // el frame 10 no depende de ningún otro
        continue;
      }

      if (frame.esStrike) {
        final bonusDisponibles = _lanzamientosBonusDisponibles(i, 2);
        if (bonusDisponibles.length == 2) frame.cerrado = true;
      } else if (frame.esSpare) {
        final bonusDisponibles = _lanzamientosBonusDisponibles(i, 1);
        if (bonusDisponibles.length == 1) frame.cerrado = true;
      } else {
        frame.cerrado = true; // frame abierto, no necesita bonus
      }
    }
  }

  /// Junta, en orden, los lanzamientos de los frames siguientes al
  /// índice [desdeFrame], hasta reunir [cantidad] lanzamientos.
  List<int> _lanzamientosBonusDisponibles(int desdeFrame, int cantidad) {
    final bonus = <int>[];
    for (var i = desdeFrame + 1; i < frames.length && bonus.length < cantidad; i++) {
      bonus.addAll(frames[i].lanzamientos);
    }
    return bonus.take(cantidad).toList();
  }

  /// Puntaje de un frame ya cerrado (10 + bonus correspondiente).
  /// Lanza si el frame todavía no está cerrado — evita reportar un
  /// puntaje parcial como si fuera definitivo.
  int puntajeFrame(int numeroFrame) {
    final frame = frames[numeroFrame - 1];
    if (!frame.cerrado) {
      throw StateError('El frame $numeroFrame aún no puede puntuarse (esperando lanzamientos bonus)');
    }
    if (frame.esFrame10) {
      return frame.lanzamientos.fold(0, (a, b) => a + b);
    }
    if (frame.esStrike) {
      final bonus = _lanzamientosBonusDisponibles(numeroFrame - 1, 2);
      return 10 + bonus.fold(0, (a, b) => a + b);
    }
    if (frame.esSpare) {
      final bonus = _lanzamientosBonusDisponibles(numeroFrame - 1, 1);
      return 10 + bonus.fold(0, (a, b) => a + b);
    }
    return frame.pinesPropios;
  }

  /// Suma el puntaje de todos los frames ya cerrados. Si la partida
  /// terminó sus 10 frames y todos están cerrados, este es el
  /// puntaje final (máximo 300).
  int puntajeTotal() {
    var total = 0;
    for (final frame in frames) {
      if (frame.cerrado) total += puntajeFrame(frame.numero);
    }
    return total;
  }

  bool get terminada => frames.every((f) => f.cerrado);
}