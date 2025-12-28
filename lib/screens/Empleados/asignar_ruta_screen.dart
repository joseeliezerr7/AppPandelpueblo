import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/auth_repository.dart';
import '../../models/user_model.dart';
import '../../services/database_helper.dart';

class AsignarRutaScreen extends StatefulWidget {
  const AsignarRutaScreen({Key? key}) : super(key: key);

  @override
  State<AsignarRutaScreen> createState() => _AsignarRutaScreenState();
}

class _AsignarRutaScreenState extends State<AsignarRutaScreen> {
  List<UserModel> _usuarios = [];
  List<Map<String, dynamic>> _rutas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final authRepository = context.read<AuthRepository>();

      // Este método prioriza servidor cuando hay conexión
      final usuarios = await authRepository.getAllUsers();

      print('===== USUARIOS OBTENIDOS =====');
      print('Total usuarios: ${usuarios.length}');
      for (var u in usuarios) {
        print('- ID: ${u.id}, Nombre: ${u.nombre}, Permiso: "${u.permiso}", RutaId: ${u.rutaId}');
      }
      print('====================================');

      final db = await DatabaseHelper.instance.database;
      final rutas = await db.query('rutas', orderBy: 'nombre');
      print('Rutas encontradas: ${rutas.length}');

      setState(() {
        _usuarios = usuarios;
        _rutas = rutas;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar datos: $e');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _asignarRuta(int usuarioId, int? rutaId, String? nombreRuta) async {
    try {
      final db = await DatabaseHelper.instance.database;

      await db.rawUpdate(
        'UPDATE users SET rutaId = ?, nombreRuta = ? WHERE id = ?',
        [rutaId, nombreRuta, usuarioId],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ruta asignada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al asignar ruta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarDialogoAsignarRuta(UserModel usuario) {
    int? rutaSeleccionada = usuario.rutaId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Asignar Ruta a ${usuario.nombre}'),
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Selecciona una ruta:'),
                const SizedBox(height: 16),
                DropdownButtonFormField<int?>(
                  value: rutaSeleccionada,
                  decoration: const InputDecoration(
                    labelText: 'Ruta',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Sin ruta asignada'),
                    ),
                    ..._rutas.map((ruta) {
                      return DropdownMenuItem<int?>(
                        value: ruta['id'] as int,
                        child: Text(ruta['nombre'] as String),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setStateDialog(() {
                      rutaSeleccionada = value;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final nombreRuta = rutaSeleccionada != null
                  ? _rutas.firstWhere((r) => r['id'] == rutaSeleccionada)['nombre'] as String
                  : null;

              _asignarRuta(
                usuario.id,
                rutaSeleccionada,
                nombreRuta,
              );
              Navigator.pop(context);
            },
            child: const Text('Asignar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asignar Rutas a Empleados'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _usuarios.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No hay usuarios registrados',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Revisa los logs de consola para más detalles',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _usuarios.length,
                    itemBuilder: (context, index) {
                      final usuario = _usuarios[index];
                      final tieneRuta = usuario.rutaId != null;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: tieneRuta ? Colors.green : Colors.grey,
                            child: Icon(
                              tieneRuta ? Icons.check : Icons.person,
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
                                    tieneRuta ? Icons.route : Icons.warning,
                                    size: 16,
                                    color: tieneRuta ? Colors.green : Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    tieneRuta
                                        ? 'Ruta: ${usuario.nombreRuta}'
                                        : 'Sin ruta asignada',
                                    style: TextStyle(
                                      color: tieneRuta ? Colors.green : Colors.orange,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: ElevatedButton.icon(
                            onPressed: () => _mostrarDialogoAsignarRuta(usuario),
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Asignar'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
