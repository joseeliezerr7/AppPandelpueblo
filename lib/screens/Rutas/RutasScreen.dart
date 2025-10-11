import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ruta_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/ruta_model.dart';
import 'RutaFormScreen.dart';

class RutasScreen extends StatefulWidget {
  const RutasScreen({Key? key}) : super(key: key);

  @override
  State<RutasScreen> createState() => _RutasScreenState();
}

class _RutasScreenState extends State<RutasScreen> {
  bool _isInitialized = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeData();
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
        await provider.loadRutas();
        if (mounted) {
          await _handleSync(showMessages: false);
        }
      } catch (e) {
        print('Error en inicialización: $e');
      }
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    }
  }

  Future<void> _handleSync({bool showMessages = true}) async {
    final provider = context.read<RutaProvider>();
    try {
      await provider.syncRutas();
      if (mounted && showMessages) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sincronización completada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted && showMessages) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en la sincronización: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmarEliminacion(BuildContext context, RutaModel ruta) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Está seguro de eliminar la ruta "${ruta.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<RutaProvider>().deleteRuta(ruta.id!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ruta eliminada correctamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.select((AuthProvider p) => p.user?.permiso == 'admin');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rutas'),
        actions: [
          Consumer<RutaProvider>(
            builder: (context, provider, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.sync),
                    onPressed: () => _handleSync(),
                  ),
                  if (provider.hayCambiosPendientes())
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          '${provider.getCambiosPendientes()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar ruta...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<RutaProvider>().updateSearch('');
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                context.read<RutaProvider>().updateSearch(value);
              },
            ),
          ),
        ),
      ),
      floatingActionButton: isAdmin ? FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RutaFormScreen(
                ruta: null,
                esNuevo: true,
              ),
            ),
          );
          if (mounted) {
            await _initializeData();
          }
        },
        child: const Icon(Icons.add),
      ) : null,
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
                  Text('Error: ${provider.error}'),
                  ElevatedButton(
                    onPressed: _initializeData,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (provider.rutasFiltradas.isEmpty) {
            return const Center(
              child: Text('No hay rutas que coincidan con la búsqueda'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _handleSync(),
            child: ListView.builder(
              itemCount: provider.rutasFiltradas.length,
              itemBuilder: (context, index) {
                final ruta = provider.rutasFiltradas[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(
                      ruta.nombre,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: ruta.sincronizado
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                ruta.sincronizado
                                    ? 'Sincronizado'
                                    : 'Pendiente de sincronizar',
                                style: TextStyle(
                                  color: ruta.sincronizado
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pulperías: ${ruta.cantidadPulperias} - Clientes: ${ruta.cantidadClientes}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: isAdmin ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RutaFormScreen(
                                  ruta: ruta,
                                  esNuevo: false,
                                ),
                              ),
                            );
                            if (mounted) {
                              await _initializeData();
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _confirmarEliminacion(context, ruta),
                        ),
                      ],
                    ) : null,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}