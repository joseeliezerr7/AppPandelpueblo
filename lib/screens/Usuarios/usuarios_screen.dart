import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import 'crear_usuario_screen.dart';
import 'editar_usuario_screen.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({Key? key}) : super(key: key);

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  String _searchQuery = '';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUsuarios();
    });
  }

  Future<void> _loadUsuarios() async {
    try {
      await context.read<UserProvider>().cargarUsuarios(forzarSync: !_isInitialized);
      setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar usuarios: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<UserModel> _usuariosFiltrados(List<UserModel> usuarios) {
    if (_searchQuery.isEmpty) return usuarios;

    final queryLower = _searchQuery.toLowerCase();
    return usuarios.where((usuario) {
      final nombre = usuario.nombre.toLowerCase();
      final email = usuario.correoElectronico.toLowerCase();
      return nombre.contains(queryLower) || email.contains(queryLower);
    }).toList();
  }

  Color _getPermisoColor(String permiso) {
    switch (permiso.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'vendedor':
        return Colors.blue;
      case 'empleado':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  IconData _getPermisoIcon(String permiso) {
    switch (permiso.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'vendedor':
        return Icons.person_outline;
      case 'empleado':
        return Icons.work_outline;
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsuarios,
            tooltip: 'Sincronizar',
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final usuarios = _usuariosFiltrados(userProvider.usuarios);
          final isLoading = userProvider.isLoading;

          return Column(
            children: [
              // Buscador
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Buscar usuario',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),

              // Lista de usuarios
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : usuarios.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'No hay usuarios registrados'
                                      : 'No se encontraron usuarios',
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadUsuarios,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: usuarios.length,
                              itemBuilder: (context, index) {
                                final usuario = usuarios[index];
                                final permiso = usuario.permiso;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: _getPermisoColor(permiso),
                                      child: Icon(
                                        _getPermisoIcon(permiso),
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(
                                      usuario.nombre,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(usuario.correoElectronico),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.badge,
                                              size: 16,
                                              color: _getPermisoColor(permiso),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              permiso.toUpperCase(),
                                              style: TextStyle(
                                                color: _getPermisoColor(permiso),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EditarUsuarioScreen(usuario: usuario),
                                        ),
                                      );

                                      if (result == true) {
                                        _loadUsuarios();
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CrearUsuarioScreen()),
          );

          if (result == true) {
            _loadUsuarios();
          }
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo Usuario'),
      ),
    );
  }
}
