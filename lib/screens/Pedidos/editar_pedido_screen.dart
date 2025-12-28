import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/pedido_model.dart';
import '../../models/producto_model.dart';
import '../../providers/pedido_provider.dart';
import '../../providers/producto_provider.dart';

class EditarPedidoScreen extends StatefulWidget {
  final PedidoModel pedido;

  const EditarPedidoScreen({
    Key? key,
    required this.pedido,
  }) : super(key: key);

  @override
  State<EditarPedidoScreen> createState() => _EditarPedidoScreenState();
}

class _EditarPedidoScreenState extends State<EditarPedidoScreen> {
  late List<DetallePedidoModel> _detalles;
  List<ProductoModel> _productos = [];
  bool _isLoading = true;
  ProductoModel? _productoSeleccionado;
  final TextEditingController _cantidadController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _detalles = widget.pedido.detalles?.map((d) => d).toList() ?? [];
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

  void _editarCantidad(int index) {
    final detalle = _detalles[index];
    final controller = TextEditingController(text: detalle.cantidad.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Cantidad'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Cantidad',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final nuevaCantidad = int.tryParse(controller.text) ?? 0;
              if (nuevaCantidad > 0) {
                setState(() {
                  _detalles[index] = detalle.copyWith(cantidad: nuevaCantidad);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarCambios() async {
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

      final pedidoActualizado = widget.pedido.copyWith(
        total: total,
      );

      await context.read<PedidoProvider>().updatePedido(
        pedidoActualizado,
        _detalles,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar pedido: $e'),
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
        title: const Text('Editar Pedido'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _guardarCambios,
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
                              widget.pedido.nombreCliente ?? 'Cliente',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.pedido.nombrePulperia != null)
                              Text(
                                widget.pedido.nombrePulperia!,
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
                                '${producto.nombre} - L${producto.precioVenta.toStringAsFixed(2)}',
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

                // Lista de productos
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
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _editarCantidad(index),
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
