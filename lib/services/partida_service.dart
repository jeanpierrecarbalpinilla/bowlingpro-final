import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/frame.dart';
import '../models/partida.dart';

/// Símbolos de bowling de un frame: X = strike, / = spare, - = cero.
/// En el frame 10 los pines se reponen tras un strike o spare.
List<String> simbolosDeFrame(Frame f) {
  final resultado = <String>[];
  int pinesEnPie = 10;
  for (final p in f.lanzamientos) {
    if (p == 10 && pinesEnPie == 10) {
      resultado.add('X');
    } else if (p == pinesEnPie) {
      resultado.add('/');
    } else {
      resultado.add(p == 0 ? '-' : '$p');
    }
    pinesEnPie -= p;
    if (pinesEnPie == 0 && f.esFrame10) pinesEnPie = 10;
  }
  return resultado;
}

/// Pines que quedan en pie para el PRÓXIMO lanzamiento del frame dado.
/// Sirve para deshabilitar en el teclado los valores imposibles.
int pinesEnPie(Frame f) {
  if (!f.esFrame10) {
    return f.lanzamientos.isEmpty ? 10 : 10 - f.lanzamientos[0];
  }
  int enPie = 10;
  for (final p in f.lanzamientos) {
    enPie -= p;
    if (enPie == 0) enPie = 10;
  }
  return enPie;
}

/// Guarda y consulta partidas en la colección 'partidas' de Firestore.
class PartidaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Guarda una partida TERMINADA. Firestore no admite arrays anidados,
  /// por eso los frames se guardan como lista de mapas.
  Future<void> guardarPartida(String uid, Partida partida) async {
    if (!partida.terminada) {
      throw StateError('Solo se puede guardar una partida terminada');
    }

    final simbolos = partida.frames.expand(simbolosDeFrame).toList();
    final strikes = simbolos.where((s) => s == 'X').length;
    final spares = simbolos.where((s) => s == '/').length;
    final pinesDerribados = partida.frames
        .expand((f) => f.lanzamientos)
        .fold<int>(0, (a, b) => a + b);

    await _db.collection('partidas').add({
      'uid': uid,
      'fecha': Timestamp.now(),
      'puntajeTotal': partida.puntajeTotal(),
      'strikes': strikes,
      'spares': spares,
      'pinesDerribados': pinesDerribados,
      'frames': partida.frames
          .map((f) => {
                'numero': f.numero,
                'lanzamientos': List<int>.from(f.lanzamientos),
              })
          .toList(),
    });
  }

  /// Partidas de un jugador, la más reciente primero. Se ordena en
  /// memoria para no exigir un índice compuesto en Firestore.
  Future<List<Map<String, dynamic>>> obtenerPartidas(String uid) async {
    final query =
        await _db.collection('partidas').where('uid', isEqualTo: uid).get();

    final partidas =
        query.docs.map((d) => {...d.data(), 'id': d.id}).toList();

    partidas.sort((a, b) {
      final fa = a['fecha'] as Timestamp;
      final fb = b['fecha'] as Timestamp;
      return fb.compareTo(fa);
    });
    return partidas;
  }
}