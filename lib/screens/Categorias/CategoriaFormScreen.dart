
// screens/Categorias/categoria_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/categoria_provider.dart';
import '../../models/categoria_model.dart';

class CategoriaFormScreen extends StatefulWidget {
  final CategoriaModel? categoria;
  final bool esNuevo;

  const CategoriaFormScreen({
    Key? key,
    this.categoria,
    required this.esNuevo,
  }) : super(key: key);

  @override
  State<CategoriaFormScreen> createState() => _CategoriaFormScreenState();
}

class _CategoriaFormScreenState extends State<CategoriaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.categoria?.nombre ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final provider = context.read<CategoriaProvider>();

      if (widget.esNuevo) {
        await provider.addCategoria(_nombreController.text);
      } else {
        final categoriaActualizada = CategoriaModel(
          id: widget.categoria!.id,
          nombre: _nombreController.text,
        );
        await provider.updateCategoria(categoriaActualizada);
      }

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.esNuevo
              ? 'Categoría creada exitosamente'
              : 'Categoría actualizada exitosamente'
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.esNuevo ? 'Nueva Categoría' : 'Editar Categoría'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ingrese el nombre de la categoría',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _guardar,
                child: Text(widget.esNuevo ? 'Crear' : 'Actualizar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}