class UserModel {
  final String uid;
  final String email;
  final String role; // 'jugador', 'entrenador', 'administrador'
  final int level;
  final Map<String, dynamic> stats;

  UserModel({
    required this.uid,
    required this.email,
    this.role = 'jugador',
    this.level = 1,
    this.stats = const {'partidas_jugadas': 0, 'promedio': 0.0},
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'level': level,
      'stats': stats,
    };
  }
}