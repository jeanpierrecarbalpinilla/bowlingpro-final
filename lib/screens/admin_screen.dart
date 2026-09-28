import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/admin_service.dart';

/// Vista del administrador: lista usuarios y les asigna grupo.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final AdminService _service = AdminService();

  bool _cargando = true;
  String? _error;
  List<Map<String, dynamic>> _usuarios = [];

  String get _adminUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final usuarios = await _service.listarUsuarios(_adminUid);
      if (!mounted) return;
      setState(() {
        _usuarios = usuarios;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e'.replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  List<String> get _gruposExistentes {
    final grupos = _usuarios
        .map((u) => u['groupId'])
        .whereType<String>()
        .where((g) => g.isNotEmpty)
        .toSet()
        .toList();
    grupos.sort();
    return grupos;
  }

  Future<void> _editar(Map<String, dynamic> usuario) async {
    final resultado = await showDialog<String>(
      context: context,
      builder: (_) => _GrupoDialog(
        email: '${usuario['email']}',
        grupoActual: usuario['groupId'] as String?,
        grupos: _gruposExistentes,
      ),
    );
    if (resultado == null) return; // cancelado

    try {
      await _service.asignarGrupo(
        adminUid: _adminUid,
        usuarioUid: '${usuario['uid']}',
        groupId: resultado,
      );
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Administrar grupos'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3A5F), Color(0xFF0D1B2A)],
          ),
        ),
        child: SafeArea(child: _contenido()),
      ),
    );
  }

  Widget _contenido() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFA726)),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
          ),
        ),
      );
    }
    if (_usuarios.isEmpty) {
      return Center(
        child: Text(
          'Aun no hay usuarios registrados.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 56, 16, 24),
      children: [
        Text(
          'Toca un usuario para asignarle grupo (${_usuarios.length})',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        ..._usuarios.map((u) {
          final esEntrenador = u['role'] == 'entrenador';
          final color = esEntrenador
              ? const Color(0xFFFFA726)
              : const Color(0xFF29B6F6);
          final grupo = u['groupId'] as String?;
          return _UsuarioTile(
            email: '${u['email']}',
            rol: '${u['role']}',
            grupo: (grupo == null || grupo.isEmpty) ? 'Sin grupo' : grupo,
            color: color,
            icono: esEntrenador
                ? Icons.sports_rounded
                : Icons.person_rounded,
            onTap: () => _editar(u),
          );
        }),
      ],
    );
  }
}

class _UsuarioTile extends StatelessWidget {
  final String email;
  final String rol;
  final String grupo;
  final Color color;
  final IconData icono;
  final VoidCallback onTap;

  const _UsuarioTile({
    required this.email,
    required this.rol,
    required this.grupo,
    required this.color,
    required this.icono,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icono, color: color, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        email,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$rol  ·  $grupo',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.edit_rounded,
                    color: Colors.white.withValues(alpha: 0.35), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialogo para elegir un grupo existente, crear uno nuevo o quitarlo.
/// Devuelve el groupId elegido, '' para quitar el grupo, o null si cancela.
class _GrupoDialog extends StatefulWidget {
  final String email;
  final String? grupoActual;
  final List<String> grupos;

  const _GrupoDialog({
    required this.email,
    required this.grupoActual,
    required this.grupos,
  });

  @override
  State<_GrupoDialog> createState() => _GrupoDialogState();
}

class _GrupoDialogState extends State<_GrupoDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.grupoActual ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E3A5F),
      title: Text(
        widget.email,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.grupos.isNotEmpty) ...[
              Text(
                'Grupos existentes',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: widget.grupos
                    .map((g) => ActionChip(
                          label: Text(g),
                          backgroundColor:
                              const Color(0xFFFFA726).withValues(alpha: 0.2),
                          labelStyle: const TextStyle(color: Colors.white),
                          onPressed: () =>
                              setState(() => _controller.text = g),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Grupo (elige uno o escribe uno nuevo)',
                labelStyle:
                    TextStyle(color: Colors.white.withValues(alpha: 0.55)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFFFA726)),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, ''),
          child: const Text('Quitar grupo'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF66BB6A),
            foregroundColor: const Color(0xFF0D1B2A),
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}