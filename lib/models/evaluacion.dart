/// Una pregunta de opción múltiple dentro de una evaluación.
class Pregunta {
  final String texto;
  final List<String> opciones;
  // Índice (0-based) de la opción correcta dentro de [opciones].
  final int respuestaCorrecta;

  Pregunta({
    required this.texto,
    required this.opciones,
    required this.respuestaCorrecta,
  });

  Map<String, dynamic> toMap() {
    return {
      'texto': texto,
      'opciones': opciones,
      'respuestaCorrecta': respuestaCorrecta,
    };
  }

  factory Pregunta.fromMap(Map<String, dynamic> map) {
    return Pregunta(
      texto: map['texto'] ?? '',
      opciones: List<String>.from(map['opciones'] ?? []),
      respuestaCorrecta: map['respuestaCorrecta'] ?? 0,
    );
  }
}

/// Evaluación al final de una lección. Corresponde a un documento
/// de la colección Firestore 'lecciones' (subcampo) o una colección
/// aparte 'evaluaciones', según se decida al integrar con Firestore.
class Evaluacion {
  final String id;
  final String leccionId;
  final List<Pregunta> preguntas;
  // Calificación mínima para aprobar, expresada como fracción (0.0 a 1.0).
  // Ej: 0.7 = 70% de respuestas correctas.
  final double calificacionMinima;

  Evaluacion({
    required this.id,
    required this.leccionId,
    required this.preguntas,
    required this.calificacionMinima,
  });

  Map<String, dynamic> toMap() {
    return {
      'leccionId': leccionId,
      'preguntas': preguntas.map((p) => p.toMap()).toList(),
      'calificacionMinima': calificacionMinima,
    };
  }

  factory Evaluacion.fromMap(String id, Map<String, dynamic> map) {
    return Evaluacion(
      id: id,
      leccionId: map['leccionId'] ?? '',
      preguntas: (map['preguntas'] as List<dynamic>? ?? [])
          .map((p) => Pregunta.fromMap(Map<String, dynamic>.from(p)))
          .toList(),
      calificacionMinima: (map['calificacionMinima'] ?? 0.7).toDouble(),
    );
  }

  /// Recibe las respuestas del usuario (índice elegido por pregunta,
  /// en el mismo orden que [preguntas]) y devuelve el puntaje obtenido
  /// como fracción entre 0.0 y 1.0.
  double calificar(List<int> respuestasUsuario) {
    if (preguntas.isEmpty) return 0.0;
    if (respuestasUsuario.length != preguntas.length) {
      throw ArgumentError(
        'La cantidad de respuestas (${respuestasUsuario.length}) no '
        'coincide con la cantidad de preguntas (${preguntas.length}).',
      );
    }

    int correctas = 0;
    for (int i = 0; i < preguntas.length; i++) {
      if (respuestasUsuario[i] == preguntas[i].respuestaCorrecta) {
        correctas++;
      }
    }
    return correctas / preguntas.length;
  }

  /// Indica si, con esas respuestas, el jugador aprueba la evaluación
  /// según [calificacionMinima]. Útil directamente en
  /// leccion_service.dart para decidir si desbloquea el siguiente nivel.
  bool aprobo(List<int> respuestasUsuario) {
    return calificar(respuestasUsuario) >= calificacionMinima;
  }
}
