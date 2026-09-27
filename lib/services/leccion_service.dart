import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leccion.dart';

/// Orden oficial de niveles, usado para saber cuál es "el nivel anterior"
/// a la hora de validar si el jugador puede avanzar.
const List<String> ordenNiveles = ['principiante', 'intermedio', 'avanzado'];

/// Servicio de la Épica 2 (Aprendizaje): obtiene lecciones por nivel y
/// aplica la regla de negocio de que un jugador no puede acceder a un
/// nivel sin haber completado y aprobado todas las lecciones del nivel
/// anterior con la calificación mínima definida.
class LeccionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Devuelve todas las lecciones de un nivel específico
  /// ('principiante' | 'intermedio' | 'avanzado').
  Future<List<Leccion>> obtenerLeccionesPorNivel(String nivel) async {
    final query = await _db
        .collection('lecciones')
        .where('nivel', isEqualTo: nivel)
        .get();

    return query.docs
        .map((doc) => Leccion.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Regla de negocio central de la Épica 2: decide si [uid] puede
  /// acceder al nivel [nivel].
  ///
  /// - El primer nivel ('principiante') siempre está disponible.
  /// - Cualquier otro nivel requiere haber completado y aprobado el
  ///   100% de las lecciones del nivel inmediatamente anterior.
  Future<bool> puedeAccederA(String nivel, String uid) async {
    final indice = ordenNiveles.indexOf(nivel);

    if (indice == -1) {
      throw ArgumentError('Nivel desconocido: $nivel');
    }
    if (indice == 0) {
      return true; // principiante siempre está abierto
    }

    final nivelAnterior = ordenNiveles[indice - 1];
    final leccionesNivelAnterior = await obtenerLeccionesPorNivel(nivelAnterior);

    if (leccionesNivelAnterior.isEmpty) {
      // Si el nivel anterior no tiene lecciones cargadas todavía,
      // no bloqueamos por un dato que no existe en el contenido.
      return true;
    }

    final progresoDoc = await _db.collection('progreso_usuario').doc(uid).get();
    if (!progresoDoc.exists) {
      return false; // no ha completado nada todavía
    }

    final data = progresoDoc.data()!;
    // Se espera un mapa: { "leccionId": { "aprobado": true/false, ... } }
    final completadas = Map<String, dynamic>.from(data['lecciones_completadas'] ?? {});

    for (final leccion in leccionesNivelAnterior) {
      final registro = completadas[leccion.id];
      final aprobo = registro != null && registro['aprobado'] == true;
      if (!aprobo) return false;
    }

    return true;
  }

  /// Marca una lección como completada (aprobada o no) para el usuario,
  /// guardando el resultado en 'progreso_usuario'. Se llama desde
  /// evaluacion_screen.dart al terminar la evaluación de una lección.
  Future<void> registrarProgreso({
    required String uid,
    required String leccionId,
    required bool aprobo,
    required double calificacionObtenida,
  }) async {
    await _db.collection('progreso_usuario').doc(uid).set({
      'lecciones_completadas': {
        leccionId: {
          'aprobado': aprobo,
          'calificacion': calificacionObtenida,
          'fecha': FieldValue.serverTimestamp(),
        },
      },
    }, SetOptions(merge: true));
  }
}