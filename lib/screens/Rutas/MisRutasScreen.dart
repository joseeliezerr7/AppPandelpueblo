import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ruta_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/ruta_model.dart';
import 'RutaPulperiasScreen.dart';

class MisRutasScreen extends StatefulWidget {
  const MisRutasScreen({Key? key}) : super(key: key);

  @override
  State<MisRutasScreen> createState() => _MisRutasScreenState();
}

class _MisRutasScreenState extends State<MisRutasScreen> {
  bool _isInitialized = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Usar addPostFrameCallback para evitar setState durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    if (!_isInitialized && mounted) {
      final provider = context.read<RutaProvider>();
      try {
        setState(() => _isInitialized = true);
        await provider.loadRutas();
      } catch (e) {
        print('Error en inicialización: $e');
        if (mounted) {
          setState(() => _isInitialized = true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Rutas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<RutaProvider>().syncRutas();
            },
            tooltip: 'Actualizar rutas',
          ),
        ],
      ),
      body: Consumer<RutaProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('Error: ${provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _initializeData,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          // Obtener rutas
          var rutas = provider.rutas;

          // Si es empleado, mostrar solo su ruta asignada
          if (user?.permiso != 'admin' && user?.rutaId != null) {
            rutas = rutas.where((r) => r.id == user!.rutaId).toList();
          }

          // Aplicar filtro de búsqueda
          if (_searchQuery.isNotEmpty) {
            rutas = rutas.where((r) {
              return r.nombre.toLowerCase().contains(_searchQuery.toLowerCase());
            }).toList();
          }

          if (rutas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.route_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'No se encontraron rutas'
                        : user?.permiso == 'admin'
                            ? 'No hay rutas creadas'
                            : 'No tienes rutas asignadas',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  if (_searchQuery.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Limpiar búsqueda'),
                    ),
                  ],
                ],
              ),
            );
          }

          return Column(
            children: [
              // Información del usuario
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.blue.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 35, color: Colors.blue),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.nombre ?? 'Usuario',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.route, size: 16, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(
                                user?.permiso == 'admin'
                                    ? '${rutas.length} ${rutas.length == 1 ? 'ruta' : 'rutas'}'
                                    : 'Mi ruta asignada',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Buscador
              if (user?.permiso == 'admin' || rutas.length > 1)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.grey[100],
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar ruta...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),

              // Contador
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.blue.shade50,
                child: Row(
                  children: [
                    Icon(Icons.route, size: 20, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      '${rutas.length} ${rutas.length == 1 ? 'ruta' : 'rutas'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Lista de rutas
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await provider.syncRutas();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: rutas.length,
                    itemBuilder: (context, index) {
                      final ruta = rutas[index];

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RutaPulperiasScreen(ruta: ruta),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.route,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ruta.nombre,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.store, size: 16, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${ruta.cantidadPulperias} ${ruta.cantidadPulperias == 1 ? 'pulpería' : 'pulperías'}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Icon(Icons.people, size: 16, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${ruta.cantidadClientes} ${ruta.cantidadClientes == 1 ? 'cliente' : 'clientes'}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey[400],
                                  size: 28,
                                ),
                              ],
                            ),
                          ),
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
      floatingActionButton: user?.permiso == 'admin'
          ? FloatingActionButton.extended(
              onPressed: () async {
                final provider = context.read<RutaProvider>();
                await provider.syncRutas();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Rutas sincronizadas'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              label: const Text('Sincronizar'),
              icon: const Icon(Icons.sync),
            )
          : null,
    );
  }
}
