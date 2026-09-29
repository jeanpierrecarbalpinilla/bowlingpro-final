import 'package:cloud_firestore/cloud_firestore.dart';
import 'partida_service.dart';

/// Definicion de una insignia del sistema de logros.
class Insignia {
  final String id;
  final String titulo;
  final String descripcion;

  const Insignia({
    required this.id,
    required this.titulo,
    required this.descripcion,
  });
}

/// Unica insignia implementada en este sprint (el resto queda en el
/// backlog de sprints futuros).
const Insignia primerStrike = Insignia(
  id: 'primer_strike',
  titulo: 'Primer strike',
  descripcion: 'Derriba los 10 pines con el primer lanzamiento de un frame.',
);

/// Servicio de la Epica 5 (Gamificacion).
/// Regla de negocio: un logro solo se desbloquea si el historial real de
/// partidas lo respalda. Nunca se otorga sin validar contra 'partidas'.
class InsigniaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final PartidaService _partidas = PartidaService();

  /// Ids de las insignias que el usuario ya tiene (users/{uid}.insignias).
  Future<Set<String>> obtenerDesbloqueadas(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    final mapa = doc.data()?['insignias'];
    if (mapa is Map) return mapa.keys.map((k) => '$k').toSet();
    return {};
  }

  /// Total de strikes en el historial de partidas guardadas del jugador.
  Future<int> totalStrikes(String uid) async {
    final partidas = await _partidas.obtenerPartidas(uid);
    return partidas.fold<int>(0, (suma, p) {
      final s = p['strikes'];
      return suma + (s is num ? s.toInt() : 0);
    });
  }

  /// Revisa el historial y desbloquea lo que corresponda.
  /// Devuelve solo las insignias recien desbloqueadas.
  Future<List<Insignia>> evaluar(String uid) async {
    final yaTiene = await obtenerDesbloqueadas(uid);
    final nuevas = <Insignia>[];

    if (!yaTiene.contains(primerStrike.id) && await totalStrikes(uid) >= 1) {
      await _db.collection('users').doc(uid).set({
        'insignias': {
          primerStrike.id: {'fecha': Timestamp.now()},
        },
      }, SetOptions(merge: true));
      nuevas.add(primerStrike);
    }

    return nuevas;
  }
}