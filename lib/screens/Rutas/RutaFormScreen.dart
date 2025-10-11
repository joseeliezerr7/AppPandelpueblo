import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ruta_provider.dart';
import '../../models/ruta_model.dart';

class RutaFormScreen extends StatefulWidget {
  final RutaModel? ruta;
  final bool esNuevo;

  const RutaFormScreen({
    Key? key,
    this.ruta,
    required this.esNuevo,
  }) : super(key: key);

  @override
  State<RutaFormScreen> createState() => _RutaFormScreenState();
}

class _RutaFormScreenState extends State<RutaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.ruta?.nombre ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _guardarRuta() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<RutaProvider>();

      if (widget.esNuevo) {
        await provider.addRuta(_nombreController.text);
      } else {
        final rutaActualizada = widget.ruta!.copyWith(
          nombre: _nombreController.text,
        );
        await provider.updateRuta(rutaActualizada);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.esNuevo
                ? 'Ruta creada exitosamente'
                : 'Ruta actualizada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.esNuevo ? 'Nueva Ruta' : 'Editar Ruta'),
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
                  labelText: 'Nombre de la ruta',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _guardarRuta,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(widget.esNuevo ? 'Crear' : 'Actualizar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}