import 'package:flutter/material.dart';
import '../../models/producto_model.dart';
import '../../providers/producto_provider.dart';
import '../../providers/categoria_provider.dart';
import 'package:provider/provider.dart';

class ProductoFormScreen extends StatefulWidget {
  final ProductoModel? producto;
  final bool esNuevo;

  const ProductoFormScreen({
    super.key,
    this.producto,
    this.esNuevo = true,
  });

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _precioCompraController;
  late TextEditingController _precioVentaController;
  late TextEditingController _cantidadController;
  int _categoriaId = 1; // Valor por defecto

  @override
  void initState() {
    super.initState();
    // Inicializar controllers con valores del producto si existe
    _nombreController = TextEditingController(text: widget.producto?.nombre ?? '');
    _precioCompraController = TextEditingController(
      text: widget.producto?.precioCompra.toString() ?? '0.0',
    );
    _precioVentaController = TextEditingController(
      text: widget.producto?.precioVenta.toString() ?? '0.0',
    );
    _cantidadController = TextEditingController(
      text: widget.producto?.cantidad.toString() ?? '0',
    );
    _categoriaId = widget.producto?.categoriaId ?? 1;

    // Cargar categorías al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoriaProvider>().loadCategorias();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.esNuevo ? 'Nuevo Producto' : 'Editar Producto'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese el nombre';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _precioCompraController,
              decoration: const InputDecoration(
                labelText: 'Precio de Compra',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese el precio de compra';
                }
                if (double.tryParse(value) == null) {
                  return 'Ingrese un número válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _precioVentaController,
              decoration: const InputDecoration(
                labelText: 'Precio de Venta',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese el precio de venta';
                }
                if (double.tryParse(value) == null) {
                  return 'Ingrese un número válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cantidadController,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese la cantidad';
                }
                if (int.tryParse(value) == null) {
                  return 'Ingrese un número válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Selector de categoría
            Consumer<CategoriaProvider>(
              builder: (context, categoriaProvider, child) {
                if (categoriaProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return DropdownButtonFormField<int>(
                  value: _categoriaId,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(),
                  ),
                  items: categoriaProvider.categorias.map((categoria) {
                    return DropdownMenuItem<int>(
                      value: categoria.id,
                      child: Text(categoria.nombre),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _categoriaId = value!;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _guardarProducto,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(widget.esNuevo ? 'Agregar' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardarProducto() async {
    if (_formKey.currentState!.validate()) {
      try {
        final productoActualizado = ProductoModel(
          id: widget.producto?.id,
          nombre: _nombreController.text,
          precioCompra: double.parse(_precioCompraController.text),
          precioVenta: double.parse(_precioVentaController.text),
          cantidad: int.parse(_cantidadController.text),
          categoriaId: _categoriaId,
        );

        final productoProvider = context.read<ProductoProvider>();

        if (widget.esNuevo) {
          await productoProvider.addProducto(productoActualizado);
        } else {
          await productoProvider.updateProducto(productoActualizado);
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.esNuevo
                ? 'Producto agregado correctamente'
                : 'Producto actualizado correctamente'
            ),
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _precioCompraController.dispose();
    _precioVentaController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }
}