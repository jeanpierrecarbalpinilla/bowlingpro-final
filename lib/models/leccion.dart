/// Modelo de una lección dentro de la Épica 2 (Aprendizaje).
/// Corresponde a un documento de la colección Firestore 'lecciones'.
class Leccion {
  final String id;
  final String titulo;
  // Nivel esperado: 'principiante' | 'intermedio' | 'avanzado'
  final String nivel;
  // URL del video o ilustración asociada a la lección.
  final String contenidoUrl;
  // Explicación paso a paso en texto (para modo offline / accesibilidad).
  final String descripcionPasoAPaso;

  Leccion({
    required this.id,
    required this.titulo,
    required this.nivel,
    required this.contenidoUrl,
    required this.descripcionPasoAPaso,
  });

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'nivel': nivel,
      'contenidoUrl': contenidoUrl,
      'descripcionPasoAPaso': descripcionPasoAPaso,
    };
  }

  factory Leccion.fromMap(String id, Map<String, dynamic> map) {
    return Leccion(
      id: id,
      titulo: map['titulo'] ?? '',
      nivel: map['nivel'] ?? 'principiante',
      contenidoUrl: map['contenidoUrl'] ?? '',
      descripcionPasoAPaso: map['descripcionPasoAPaso'] ?? '',
    );
  }
}
