import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/pedido_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/pedido_model.dart';
import 'pedido_detalle_screen.dart';
import 'editar_pedido_screen.dart';
import 'crear_pedido_screen.dart';

class PedidosScreen extends StatefulWidget {
  const PedidosScreen({Key? key}) : super(key: key);

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
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
      final provider = context.read<PedidoProvider>();
      try {
        await provider.loadPedidos();
        if (mounted) {
          setState(() => _isInitialized = true);
        }
      } catch (e) {
        print('Error en inicialización: $e');
      }
    }
  }

  Future<void> _handleSync() async {
    final provider = context.read<PedidoProvider>();
    try {
      await provider.syncPedidos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sincronización completada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en la sincronización: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmarEliminacion(BuildContext context, PedidoModel pedido) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Está seguro de eliminar el pedido de "${pedido.nombreCliente}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<PedidoProvider>().deletePedido(pedido.id!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pedido eliminado correctamente'),
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
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
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
        title: const Text('Pedidos'),
        actions: [
          Consumer<PedidoProvider>(
            builder: (context, provider, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.sync),
                    onPressed: _handleSync,
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
                hintText: 'Buscar por cliente o pulpería...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<PedidoProvider>().updateSearch('');
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                context.read<PedidoProvider>().updateSearch(value);
              },
            ),
          ),
        ),
      ),
      body: Consumer<PedidoProvider>(
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

          if (provider.pedidosFiltrados.isEmpty) {
            return const Center(
              child: Text('No hay pedidos registrados'),
            );
          }

          return RefreshIndicator(
            onRefresh: _handleSync,
            child: ListView.builder(
              itemCount: provider.pedidosFiltrados.length,
              itemBuilder: (context, index) {
                final pedido = provider.pedidosFiltrados[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PedidoDetalleScreen(pedido: pedido),
                        ),
                      );
                      _initializeData();
                    },
                    child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: pedido.sincronizado ? Colors.green : Colors.orange,
                      child: const Icon(
                        Icons.shopping_cart,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      pedido.nombreCliente ?? 'Cliente',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (pedido.nombrePulperia != null)
                          Text(
                            pedido.nombrePulperia!,
                            style: const TextStyle(fontSize: 12),
                          ),
                        Text(
                          _formatFecha(pedido.fecha),
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: pedido.sincronizado
                                ? Colors.green.withOpacity(0.2)
                                : Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            pedido.sincronizado
                                ? 'Sincronizado'
                                : 'Pendiente de sincronizar',
                            style: TextStyle(
                              color: pedido.sincronizado
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: Text(
                      'L ${pedido.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    children: [
                      if (pedido.detalles != null && pedido.detalles!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(),
                              const Text(
                                'Detalles del Pedido:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...pedido.detalles!.map((detalle) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          detalle.nombreProducto ?? 'Producto',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      Text(
                                        '${detalle.cantidad} x L${detalle.precio.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'L${detalle.subtotal.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              const SizedBox(height: 8),
                              // Botones de acción
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PedidoDetalleScreen(pedido: pedido),
                                        ),
                                      );
                                      _initializeData();
                                    },
                                    icon: const Icon(Icons.visibility),
                                    label: const Text('Ver Detalles'),
                                  ),
                                  if (isAdmin) ...[
                                    TextButton.icon(
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => EditarPedidoScreen(pedido: pedido),
                                          ),
                                        );
                                        if (result == true) {
                                          _initializeData();
                                        }
                                      },
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Editar'),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => _confirmarEliminacion(context, pedido),
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CrearPedidoScreen(),
            ),
          );
          if (result == true) {
            _initializeData();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Pedido'),
      ),
    );
  }

  String _formatFecha(String fecha) {
    try {
      final date = DateTime.parse(fecha);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return fecha;
    }
  }
}
