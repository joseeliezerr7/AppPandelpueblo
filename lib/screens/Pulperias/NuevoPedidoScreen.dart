import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/cliente_model.dart';
import '../../models/pulperia_model.dart';
import '../../models/pedido_model.dart';
import '../../models/producto_model.dart';
import '../../providers/pedido_provider.dart';
import '../../providers/producto_provider.dart';
import '../Pedidos/TicketPedidoScreen.dart';

class NuevoPedidoScreen extends StatefulWidget {
  final ClienteModel cliente;
  final PulperiaModel pulperia;

  const NuevoPedidoScreen({
    Key? key,
    required this.cliente,
    required this.pulperia,
  }) : super(key: key);

  @override
  State<NuevoPedidoScreen> createState() => _NuevoPedidoScreenState();
}

class _NuevoPedidoScreenState extends State<NuevoPedidoScreen> {
  final List<DetallePedidoModel> _detalles = [];
  List<ProductoModel> _productos = [];
  bool _isLoading = true;
  bool _isSaving = false;
  ProductoModel? _productoSeleccionado;
  final TextEditingController _cantidadController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProductos();
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  Future<void> _loadProductos() async {
    try {
      setState(() => _isLoading = true);

      final productoProvider = context.read<ProductoProvider>();
      await productoProvider.loadProductos();

      setState(() {
        _productos = productoProvider.productos;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar productos: $e');
      setState(() => _isLoading = false);
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
    if (_detalles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos un producto'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final total = _detalles.fold<double>(
        0,
        (sum, detalle) => sum + detalle.subtotal,
      );

      final pedido = PedidoModel(
        clienteId: widget.cliente.id!,
        nombreCliente: widget.cliente.nombre,
        pulperiaId: widget.pulperia.id,
        nombrePulperia: widget.pulperia.nombre,
        fecha: DateTime.now().toIso8601String(),
        total: total,
      );

      print('Guardando pedido...');

      // Guardar el pedido y obtener el pedido creado con ID
      final pedidoProvider = context.read<PedidoProvider>();
      final pedidoCreado = await pedidoProvider.addPedido(pedido, _detalles);

      print('Pedido guardado con ID: ${pedidoCreado.id}');

      if (mounted) {
        // Agregar los detalles al pedido para el ticket
        final pedidoConDetalles = pedidoCreado.copyWith(detalles: _detalles);

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido guardado correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        print('Navegando al ticket...');

        // Navegar al ticket
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TicketPedidoScreen(pedido: pedidoConDetalles),
          ),
        );

        print('Regresando de ticket...');

        // Después de cerrar el ticket, regresar a la pantalla anterior
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print('Error al guardar pedido: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar pedido: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
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
        title: const Text('Nuevo Pedido'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
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
                // Información del cliente
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue.shade50,
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.cliente.nombre,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.pulperia.nombre,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Formulario de agregar producto
                Card(
                  margin: const EdgeInsets.all(16),
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
                          decoration: const InputDecoration(
                            labelText: 'Producto',
                            border: OutlineInputBorder(),
                          ),
                          items: _productos.map((producto) {
                            return DropdownMenuItem(
                              value: producto,
                              child: Text(
                                '${producto.nombre} - L${producto.precioVenta.toStringAsFixed(2)} (Stock: ${producto.cantidad})',
                              ),
                            );
                          }).toList(),
                          onChanged: _isSaving ? null : (value) {
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
                          enabled: !_isSaving,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _isSaving ? null : _agregarProducto,
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar'),
                        ),
                      ],
                    ),
                  ),
                ),

                // Lista de productos agregados
                Expanded(
                  child: _detalles.isEmpty
                      ? const Center(
                          child: Text('No hay productos agregados'),
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
                                      onPressed: _isSaving ? null : () => _eliminarDetalle(index),
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
