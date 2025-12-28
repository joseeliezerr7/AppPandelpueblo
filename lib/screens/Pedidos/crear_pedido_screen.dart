import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/pedido_model.dart';
import '../../models/producto_model.dart';
import '../../models/pulperia_model.dart';
import '../../providers/pedido_provider.dart';
import '../../providers/producto_provider.dart';
import '../../providers/pulperia_provider.dart';

class CrearPedidoScreen extends StatefulWidget {
  const CrearPedidoScreen({Key? key}) : super(key: key);

  @override
  State<CrearPedidoScreen> createState() => _CrearPedidoScreenState();
}

class _CrearPedidoScreenState extends State<CrearPedidoScreen> {
  final List<DetallePedidoModel> _detalles = [];

  PulperiaModel? _pulperiaSeleccionada;
  ProductoModel? _productoSeleccionado;
  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _pulperiaSearchController = TextEditingController();
  final TextEditingController _productoSearchController = TextEditingController();

  String _pulperiaSearch = '';
  String _productoSearch = '';

  @override
  void dispose() {
    _cantidadController.dispose();
    _pulperiaSearchController.dispose();
    _productoSearchController.dispose();
    super.dispose();
  }

  List<PulperiaModel> _getPulperiasFiltradas(List<PulperiaModel> pulperias) {
    // Filtrar solo pulperías NO visitadas
    var filtradas = pulperias.where((p) => !p.visitado).toList();

    // Aplicar búsqueda
    if (_pulperiaSearch.isNotEmpty) {
      filtradas = filtradas.where((p) =>
        p.nombre.toLowerCase().contains(_pulperiaSearch.toLowerCase()) ||
        p.direccion.toLowerCase().contains(_pulperiaSearch.toLowerCase())
      ).toList();
    }

    return filtradas;
  }

  List<ProductoModel> _getProductosFiltrados(List<ProductoModel> productos) {
    if (_productoSearch.isEmpty) return productos;

    return productos.where((p) =>
      p.nombre.toLowerCase().contains(_productoSearch.toLowerCase())
    ).toList();
  }

  void _agregarProducto() {
    if (_productoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un producto'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final cantidad = int.tryParse(_cantidadController.text) ?? 0;
    if (cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa una cantidad válida'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (cantidad > _productoSeleccionado!.cantidad) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Solo hay ${_productoSeleccionado!.cantidad} unidades disponibles'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _detalles.add(
        DetallePedidoModel(
          productoId: _productoSeleccionado!.id!,
          nombreProducto: _productoSeleccionado!.nombre,
          cantidad: cantidad,
          precio: _productoSeleccionado!.precioVenta,
        ),
      );

      _productoSeleccionado = null;
      _cantidadController.clear();
    });
  }

  void _eliminarDetalle(int index) {
    setState(() {
      _detalles.removeAt(index);
    });
  }

  Future<void> _guardarPedido() async {
    if (_pulperiaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una pulpería/cliente'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_detalles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos un producto'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final total = _detalles.fold<double>(
        0,
        (sum, detalle) => sum + detalle.subtotal,
      );

      // La pulpería ES el cliente
      final pedido = PedidoModel(
        clienteId: _pulperiaSeleccionada!.id!,
        nombreCliente: _pulperiaSeleccionada!.nombre,
        pulperiaId: _pulperiaSeleccionada!.id,
        nombrePulperia: _pulperiaSeleccionada!.nombre,
        fecha: DateTime.now().toIso8601String(),
        total: total,
      );

      await context.read<PedidoProvider>().addPedido(pedido, _detalles);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido creado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear pedido: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _detalles.fold<double>(
      0,
      (sum, detalle) => sum + detalle.subtotal,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Pedido'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _guardarPedido,
          ),
        ],
      ),
      body: Consumer2<PulperiaProvider, ProductoProvider>(
              builder: (context, pulperiaProvider, productoProvider, child) {
                final pulperiasFiltradas = _getPulperiasFiltradas(pulperiaProvider.pulperias);
                final productosFiltrados = _getProductosFiltrados(productoProvider.productos);

                return Column(
              children: [
                // Selección de Pulpería (Cliente)
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.store, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'Cliente',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _pulperiaSearchController,
                          decoration: InputDecoration(
                            labelText: 'Buscar Pulpería',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _pulperiaSearch.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _pulperiaSearchController.clear();
                                        _pulperiaSearch = '';
                                      });
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _pulperiaSearch = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<PulperiaModel>(
                          value: pulperiasFiltradas.contains(_pulperiaSeleccionada)
                              ? _pulperiaSeleccionada
                              : null,
                          decoration: InputDecoration(
                            labelText: 'Seleccionar Pulpería *',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.store_outlined),
                            helperText: pulperiasFiltradas.isEmpty
                                ? 'No hay pulperías sin visitar'
                                : 'Solo pulperías sin visitar',
                            helperStyle: TextStyle(
                              color: pulperiasFiltradas.isEmpty ? Colors.orange : Colors.blue.shade600,
                            ),
                          ),
                          items: pulperiasFiltradas.isEmpty
                              ? null
                              : pulperiasFiltradas.map((pulperia) {
                                  return DropdownMenuItem(
                                    value: pulperia,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          pulperia.nombre,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          pulperia.direccion,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _pulperiaSeleccionada = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Formulario de agregar producto
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.inventory_2, color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              'Agregar Productos',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _productoSearchController,
                          decoration: InputDecoration(
                            labelText: 'Buscar Producto',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _productoSearch.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _productoSearchController.clear();
                                        _productoSearch = '';
                                      });
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _productoSearch = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<ProductoModel>(
                          value: _productoSeleccionado != null && productosFiltrados.contains(_productoSeleccionado)
                              ? _productoSeleccionado
                              : null,
                          decoration: InputDecoration(
                            labelText: 'Producto',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.shopping_bag_outlined),
                            helperText: productosFiltrados.isEmpty
                                ? 'No hay productos que coincidan con la búsqueda'
                                : _productoSeleccionado != null
                                    ? 'Producto seleccionado'
                                    : null,
                            helperStyle: TextStyle(
                              color: productosFiltrados.isEmpty
                                  ? Colors.orange
                                  : Colors.green.shade700
                            ),
                          ),
                          items: productosFiltrados.isEmpty
                              ? null
                              : productosFiltrados.map((producto) {
                                  return DropdownMenuItem(
                                    value: producto,
                                    child: Text(
                                      '${producto.nombre} - L${producto.precioVenta.toStringAsFixed(2)} (Stock: ${producto.cantidad})',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  );
                                }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _productoSeleccionado = value;
                              // Limpiar búsqueda al seleccionar
                              if (value != null) {
                                _productoSearchController.clear();
                                _productoSearch = '';
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _cantidadController,
                          decoration: const InputDecoration(
                            labelText: 'Cantidad',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.pin),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _agregarProducto,
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('Agregar al Pedido'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Lista de productos agregados
                Expanded(
                  child: _detalles.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hay productos en el pedido',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Agrega productos arriba',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _detalles.length,
                          itemBuilder: (context, index) {
                            final detalle = _detalles[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade50,
                                  child: Text(
                                    '${detalle.cantidad}',
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  detalle.nombreProducto ?? 'Producto',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'L${detalle.precio.toStringAsFixed(2)} c/u',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'L${detalle.subtotal.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => _eliminarDetalle(index),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Total
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL:',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'L${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
              },
            ),
    );
  }
}
