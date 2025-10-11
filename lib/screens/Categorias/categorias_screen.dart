import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/categoria_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/categoria_model.dart';
import 'CategoriaFormScreen.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({Key? key}) : super(key: key);

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
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
      final provider = context.read<CategoriaProvider>();
      try {
        await provider.loadCategorias();
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
    final provider = context.read<CategoriaProvider>();
    try {
      await provider.syncCategorias();
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

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.select((AuthProvider p) => p.user?.permiso == 'admin');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        actions: [
          Consumer<CategoriaProvider>(
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
                hintText: 'Buscar categoría...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<CategoriaProvider>().updateSearch('');
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                context.read<CategoriaProvider>().updateSearch(value);
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
              builder: (_) => const CategoriaFormScreen(
                categoria: null,
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
      body: Consumer<CategoriaProvider>(
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

          if (provider.categoriasFiltradas.isEmpty) {
            return const Center(
              child: Text('No hay categorías que coincidan con la búsqueda'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _handleSync(),
            child: ListView.builder(
              itemCount: provider.categoriasFiltradas.length,
              itemBuilder: (context, index) {
                final categoria = provider.categoriasFiltradas[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(
                      categoria.nombre,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: categoria.sincronizado
                                ? Colors.green.withOpacity(0.2)
                                : Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            categoria.sincronizado
                                ? 'Sincronizado'
                                : 'Pendiente de sincronizar',
                            style: TextStyle(
                              color: categoria.sincronizado
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                              fontSize: 12,
                            ),
                          ),
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
                                builder: (_) => CategoriaFormScreen(
                                  categoria: categoria,
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
                          onPressed: () => _confirmarEliminacion(context, categoria),
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

  void _confirmarEliminacion(BuildContext context, CategoriaModel categoria) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Está seguro de eliminar la categoría "${categoria.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<CategoriaProvider>().deleteCategoria(categoria.id!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Categoría eliminada correctamente'),
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
}