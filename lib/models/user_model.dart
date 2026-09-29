class UserModel {
  final String uid;
  final String email;
  final String role; // 'jugador', 'entrenador', 'administrador'
  final int level;
  final Map<String, dynamic> stats;
  final String? groupId; // grupo del jugador, o grupo que supervisa el entrenador

  UserModel({
    required this.uid,
    required this.email,
    this.role = 'jugador',
    this.level = 1,
    this.stats = const {'partidas_jugadas': 0, 'promedio': 0.0},
    this.groupId,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'level': level,
      'stats': stats,
      'groupId': groupId,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'],
      email: data['email'],
      role: data['role'] ?? 'jugador',
      level: data['level'] ?? 1,
      stats: Map<String, dynamic>.from(data['stats'] ?? {}),
      groupId: data['groupId'],
    );
  }
}