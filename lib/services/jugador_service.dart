import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Servicio que aplica la regla de negocio de HU03:
/// un entrenador solo puede ver a los jugadores de su propio grupo.
class JugadorService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Devuelve los jugadores del mismo grupo que el entrenador dado.
  /// Lanza una excepción si quien llama no tiene rol 'entrenador' o
  /// no tiene un grupo asignado — así la restricción no depende solo
  /// de la interfaz, sino de este servicio.
  Future<List<UserModel>> obtenerJugadoresDelGrupo(String entrenadorUid) async {
    final entrenadorDoc = await _db.collection('users').doc(entrenadorUid).get();

    if (!entrenadorDoc.exists) {
      throw Exception('Entrenador no encontrado');
    }

    final entrenador = UserModel.fromMap(entrenadorDoc.data()!);

    if (entrenador.role != 'entrenador') {
      throw Exception('Solo un usuario con rol entrenador puede consultar jugadores de un grupo');
    }
    if (entrenador.groupId == null) {
      throw Exception('Este entrenador no tiene un grupo asignado todavía');
    }

    final query = await _db
        .collection('users')
        .where('role', isEqualTo: 'jugador')
        .where('groupId', isEqualTo: entrenador.groupId)
        .get();

    return query.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
  }
}