import 'package:flutter_test/flutter_test.dart';
import 'package:bowling_pro/models/partida.dart';

void jugar(Partida partida, List<int> lanzamientos) {
  for (final pines in lanzamientos) {
    partida.registrarLanzamiento(pines);
  }
}

void main() {
  group('Motor de puntuación oficial de bowling', () {
    test('Juego perfecto: 12 strikes seguidos = 300 puntos', () {
      final partida = Partida();
      jugar(partida, List.filled(12, 10));

      expect(partida.terminada, isTrue);
      expect(partida.puntajeTotal(), equals(300));
    });

    test('Juego en cero: todos los lanzamientos fallan (gutter) = 0 puntos', () {
      final partida = Partida();
      jugar(partida, List.filled(20, 0));

      expect(partida.terminada, isTrue);
      expect(partida.puntajeTotal(), equals(0));
    });

    test('Mezcla de strikes y spares en distintos frames', () {
      final partida = Partida();
      jugar(partida, [
        10,
        5, 5,
        10,
        4, 3,
        4, 3,
        4, 3,
        4, 3,
        4, 3,
        4, 3,
        6, 4, 5,
      ]);

      expect(partida.terminada, isTrue);
      expect(partida.puntajeFrame(1), equals(20));
      expect(partida.puntajeFrame(2), equals(20));
      expect(partida.puntajeFrame(3), equals(17));
      expect(partida.puntajeFrame(10), equals(15));
      expect(partida.puntajeTotal(), equals(20 + 20 + 17 + 42 + 15));
    });

    test('Frame 10 límite: spare en el último frame habilita un tercer lanzamiento', () {
      final partida = Partida();
      jugar(partida, [
        ...List.filled(9, 0),
        ...List.filled(9, 0),
        7, 3, 9,
      ]);

      final frame10 = partida.frames[9];
      expect(frame10.lanzamientos.length, equals(3));
      expect(partida.terminada, isTrue);
      expect(partida.puntajeFrame(10), equals(7 + 3 + 9));
      expect(partida.puntajeTotal(), equals(19));
    });

    test('Bloqueo circular: un strike no se puntúa hasta tener sus 2 bonus', () {
      final partida = Partida();
      partida.registrarLanzamiento(10);

      expect(partida.frames[0].cerrado, isFalse,
          reason: 'F1 no debe cerrarse sin sus 2 lanzamientos bonus');

      partida.registrarLanzamiento(4);
      expect(partida.frames[0].cerrado, isFalse,
          reason: 'Todavía falta el segundo lanzamiento bonus');

      partida.registrarLanzamiento(3);
      expect(partida.frames[0].cerrado, isTrue);
      expect(partida.puntajeFrame(1), equals(10 + 4 + 3));
    });
  });
}