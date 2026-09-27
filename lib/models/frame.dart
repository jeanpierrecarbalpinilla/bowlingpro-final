/// Representa un frame individual de una partida de bolos.
///
/// Un frame guarda sus lanzamientos crudos (pines derribados por tiro)
/// y se marca [cerrado] únicamente cuando ya existen todos los datos
/// necesarios para calcular su puntaje final — incluyendo, si aplica,
/// los lanzamientos bonus de strike/spare (regla de "bloqueo circular").
class Frame {
  final int numero; // 1..10
  final List<int> lanzamientos = [];
  bool cerrado = false;

  Frame(this.numero);

  bool get esFrame10 => numero == 10;

  /// Un strike ocurre cuando el primer lanzamiento derriba los 10 pines.
  bool get esStrike => lanzamientos.isNotEmpty && lanzamientos[0] == 10;

  /// Un spare ocurre cuando los dos primeros lanzamientos suman 10,
  /// sin que el primero haya sido ya un strike.
  bool get esSpare =>
      lanzamientos.length >= 2 &&
      !esStrike &&
      lanzamientos[0] + lanzamientos[1] == 10;

  /// Pines derribados solo con los lanzamientos propios de este frame
  /// (sin contar los bonus de strike/spare, que los calcula Partida).
  int get pinesPropios {
    if (esFrame10) {
      return lanzamientos.fold(0, (a, b) => a + b);
    }
    return lanzamientos.take(2).fold(0, (a, b) => a + b);
  }

  /// Cuántos lanzamientos más puede recibir este frame.
  bool get completo {
    if (esFrame10) {
      // El frame 10 admite hasta 3 lanzamientos si hubo strike o spare,
      // o 2 lanzamientos si quedó abierto.
      if (lanzamientos.length < 2) return false;
      final huboBonusDerecho = lanzamientos[0] == 10 ||
          (lanzamientos.length >= 2 && lanzamientos[0] + lanzamientos[1] == 10);
      if (huboBonusDerecho) return lanzamientos.length >= 3;
      return true;
    }
    // Frames 1-9: un strike cierra el frame con un solo lanzamiento;
    // si no, se necesitan 2.
    if (lanzamientos.isNotEmpty && lanzamientos[0] == 10) return true;
    return lanzamientos.length >= 2;
  }
}