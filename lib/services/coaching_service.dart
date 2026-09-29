import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'jugador_service.dart';
import 'partida_service.dart';

/// Servicio de la Épica 4 (Coaching activo).
/// Regla de negocio: el entrenador solo puede ver y comentar el progreso
/// de los jugadores asignados a su grupo. Se valida aquí, no solo en la UI.
class CoachingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final JugadorService _jugadores = JugadorService();
  final PartidaService _partidas = PartidaService();

  /// Jugadores del grupo del entrenador (valida rol y grupo).
  Future<List<UserModel>> jugadoresDelGrupo(String entrenadorUid) {
    return _jugadores.obtenerJugadoresDelGrupo(entrenadorUid);
  }

  /// Lanza si [jugadorUid] no pertenece al grupo del entrenador.
  Future<void> _validarPertenencia(
      String entrenadorUid, String jugadorUid) async {
    final grupo = await jugadoresDelGrupo(entrenadorUid);
    if (!grupo.any((j) => j.uid == jugadorUid)) {
      throw Exception('Este jugador no pertenece a tu grupo');
    }
  }

  /// Partidas de un jugador del grupo, la más reciente primero.
  Future<List<Map<String, dynamic>>> partidasDeJugador(
      String entrenadorUid, String jugadorUid) async {
    await _validarPertenencia(entrenadorUid, jugadorUid);
    return _partidas.obtenerPartidas(jugadorUid);
  }

  /// Guarda un comentario del entrenador sobre un jugador de su grupo.
  Future<void> guardarComentario({
    required String entrenadorUid,
    required String jugadorUid,
    required String texto,
  }) async {
    final limpio = texto.trim();
    if (limpio.isEmpty) {
      throw ArgumentError('El comentario no puede estar vacío');
    }
    await _validarPertenencia(entrenadorUid, jugadorUid);

    await _db.collection('comentarios').add({
      'jugadorUid': jugadorUid,
      'entrenadorUid': entrenadorUid,
      'texto': limpio,
      'fecha': Timestamp.now(),
    });
  }

  /// Comentarios recibidos por un jugador, el más reciente primero.
  /// Se ordena en memoria para no exigir un índice compuesto.
  Future<List<Map<String, dynamic>>> obtenerComentarios(
      String jugadorUid) async {
    final query = await _db
        .collection('comentarios')
        .where('jugadorUid', isEqualTo: jugadorUid)
        .get();

    final lista = query.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    lista.sort((a, b) {
      final fa = a['fecha'] as Timestamp;
      final fb = b['fecha'] as Timestamp;
      return fb.compareTo(fa);
    });
    return lista;
  }
}