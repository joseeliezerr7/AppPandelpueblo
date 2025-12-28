import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/pedido_model.dart';
import '../../models/producto_model.dart';
import '../../models/cliente_model.dart';
import '../../models/pulperia_model.dart';
import '../../providers/pedido_provider.dart';
import '../../providers/producto_provider.dart';
import '../../providers/cliente_provider.dart';
import '../../providers/pulperia_provider.dart';

class CrearPedidoScreen extends StatefulWidget {
  const CrearPedidoScreen({Key? key}) : super(key: key);

  @override
  State<CrearPedidoScreen> createState() => _CrearPedidoScreenState();
}

class _CrearPedidoScreenState extends State<CrearPedidoScreen> {
  final List<DetallePedidoModel> _detalles = [];
  List<ProductoModel> _productos = [];
  List<ClienteModel> _clientes = [];
  List<PulperiaModel> _pulperias = [];
  bool _isLoading = true;

  ClienteModel? _clienteSeleccionado;
  PulperiaModel? _pulperiaSeleccionada;
  ProductoModel? _productoSeleccionado;
  final TextEditingController _cantidadController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      final productoProvider = context.read<ProductoProvider>();
      final clienteProvider = context.read<ClienteProvider>();
      final pulperiaProvider = context.read<PulperiaProvider>();

      await Future.wait([
        productoProvider.loadProductos(),
        clienteProvider.loadClientes(),
        pulperiaProvider.loadPulperias(),
      ]);

      setState(() {
        _productos = productoProvider.productos;
        _clientes = clienteProvider.clientes;
        _pulperias = pulperiaProvider.pulperias;
        _isLoading = false;
      });

      // Mostrar alertas si no hay datos
      if (_clientes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay clientes registrados. Por favor, agregue clientes primero.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }

      if (_productos.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay productos registrados. Por favor, agregue productos primero.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
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
    if (_clienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un cliente'),
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

      final pedido = PedidoModel(
        clienteId: _clienteSeleccionado!.id!,
        nombreCliente: _clienteSeleccionado!.nombre,
        pulperiaId: _pulperiaSeleccionada?.id,
        nombrePulperia: _pulperiaSeleccionada?.nombre,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Selección de Cliente y Pulpería
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Información del Pedido',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<ClienteModel>(
                          value: _clienteSeleccionado,
                          decoration: InputDecoration(
                            labelText: 'Cliente *',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.person),
                            helperText: _clientes.isEmpty ? 'No hay clientes disponibles' : null,
                            helperStyle: const TextStyle(color: Colors.orange),
                          ),
                          items: _clientes.isEmpty
                              ? null
                              : _clientes.map((cliente) {
                                  return DropdownMenuItem(
                                    value: cliente,
                                    child: Text(cliente.nombre),
                                  );
                                }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _clienteSeleccionado = value;
                              // Si el cliente tiene una pulpería asignada, seleccionarla
                              if (value?.pulperiaId != null) {
                                _pulperiaSeleccionada = _pulperias.firstWhere(
                                  (p) => p.id == value!.pulperiaId,
                                  orElse: () => _pulperias.first,
                                );
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<PulperiaModel>(
                          value: _pulperiaSeleccionada,
                          decoration: InputDecoration(
                            labelText: 'Pulpería (Opcional)',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.store),
                            helperText: _pulperias.isEmpty ? 'No hay pulperías disponibles' : null,
                            helperStyle: const TextStyle(color: Colors.orange),
                          ),
                          items: _pulperias.isEmpty
                              ? null
                              : _pulperias.map((pulperia) {
                                  return DropdownMenuItem(
                                    value: pulperia,
                                    child: Text(pulperia.nombre),
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
                        const Text(
                          'Agregar Producto',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<ProductoModel>(
                          value: _productoSeleccionado,
                          decoration: InputDecoration(
                            labelText: 'Producto',
                            border: const OutlineInputBorder(),
                            helperText: _productos.isEmpty ? 'No hay productos disponibles' : null,
                            helperStyle: const TextStyle(color: Colors.orange),
                          ),
                          items: _productos.isEmpty
                              ? null
                              : _productos.map((producto) {
                                  return DropdownMenuItem(
                                    value: producto,
                                    child: Text(
                                      '${producto.nombre} - L${producto.precioVenta.toStringAsFixed(2)} (Stock: ${producto.cantidad})',
                                    ),
                                  );
                                }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _productoSeleccionado = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _cantidadController,
                          decoration: const InputDecoration(
                            labelText: 'Cantidad',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _agregarProducto,
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Lista de productos agregados
                Expanded(
                  child: _detalles.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No hay productos agregados',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _detalles.length,
                          itemBuilder: (context, index) {
                            final detalle = _detalles[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: ListTile(
                                title: Text(
                                  detalle.nombreProducto ?? 'Producto',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '${detalle.cantidad} x L${detalle.precio.toStringAsFixed(2)}',
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
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'L${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
