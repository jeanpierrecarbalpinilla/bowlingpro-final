import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio del administrador: vincula usuarios a grupos.
/// Entrenador y jugadores con el mismo groupId quedan vinculados.
/// Regla de negocio: solo el rol 'administrador' puede hacerlo; se valida
/// aqui y no solo en la interfaz.
class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> _validarAdmin(String adminUid) async {
    final doc = await _db.collection('users').doc(adminUid).get();
    if (doc.data()?['role'] != 'administrador') {
      throw Exception('Solo un administrador puede gestionar grupos');
    }
  }

  /// Todos los usuarios que no son administradores, ordenados por rol y correo.
  Future<List<Map<String, dynamic>>> listarUsuarios(String adminUid) async {
    await _validarAdmin(adminUid);
    final query = await _db.collection('users').get();

    final lista = query.docs
        .map((d) => {...d.data(), 'uid': d.id})
        .where((u) => u['role'] != 'administrador')
        .toList();

    lista.sort((a, b) {
      final porRol = '${a['role']}'.compareTo('${b['role']}');
      if (porRol != 0) return porRol;
      return '${a['email']}'.compareTo('${b['email']}');
    });
    return lista;
  }

  /// Asigna [groupId] a un usuario. Si es null o vacio, le quita el grupo
  /// (se borra el campo, asi groupId sigue siendo nullable).
  Future<void> asignarGrupo({
    required String adminUid,
    required String usuarioUid,
    String? groupId,
  }) async {
    await _validarAdmin(adminUid);

    final limpio = groupId?.trim().toLowerCase() ?? '';
    await _db.collection('users').doc(usuarioUid).update({
      'groupId': limpio.isEmpty ? FieldValue.delete() : limpio,
    });
  }
}