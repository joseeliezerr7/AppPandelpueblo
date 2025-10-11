import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/pulperia_model.dart';
import '../../models/ruta_model.dart';
import '../../providers/pulperia_provider.dart';
import '../../providers/ruta_provider.dart';

class PulperiaFormScreen extends StatefulWidget {
  final PulperiaModel? pulperia;
  final bool esNuevo;

  const PulperiaFormScreen({
    Key? key,
    this.pulperia,
    required this.esNuevo,
  }) : super(key: key);

  @override
  State<PulperiaFormScreen> createState() => _PulperiaFormScreenState();
}

class _PulperiaFormScreenState extends State<PulperiaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _direccionController;
  late TextEditingController _telefonoController;
  RutaModel? _rutaSeleccionada;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.pulperia?.nombre ?? '');
    _direccionController = TextEditingController(text: widget.pulperia?.direccion ?? '');
    _telefonoController = TextEditingController(text: widget.pulperia?.telefono ?? '');
    _cargarRutas();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _cargarRutas() async {
    try {
      final rutaProvider = context.read<RutaProvider>();
      await rutaProvider.loadRutas();

      if (widget.pulperia?.rutaId != null && mounted) {
        final rutas = rutaProvider.rutas;
        _rutaSeleccionada = rutas.firstWhere(
              (ruta) => ruta.id == widget.pulperia!.rutaId,
          orElse: () => rutas.first,
        );
      }
    } catch (e) {
      print('Error al cargar rutas: $e');
    }
  }

  Future<void> _guardarPulperia() async {
    if (!_formKey.currentState!.validate()) return;

    if (_rutaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione una ruta'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = context.read<PulperiaProvider>();
      final pulperia = PulperiaModel(
        id: widget.pulperia?.id,
        nombre: _nombreController.text,
        direccion: _direccionController.text,
        telefono: _telefonoController.text,
        rutaId: _rutaSeleccionada!.id,
        nombreRuta: _rutaSeleccionada!.nombre,
      );

      if (widget.esNuevo) {
        await provider.addPulperia(pulperia);
      } else {
        await provider.updatePulperia(pulperia);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                widget.esNuevo
                    ? 'Pulpería creada exitosamente'
                    : 'Pulpería actualizada exitosamente'
            ),
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
        title: Text(widget.esNuevo ? 'Nueva Pulpería' : 'Editar Pulpería'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la pulpería',
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
              TextFormField(
                controller: _direccionController,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              Consumer<RutaProvider>(
                builder: (context, rutaProvider, child) {
                  if (rutaProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final rutas = rutaProvider.rutas;
                  if (rutas.isEmpty) {
                    return const Center(
                      child: Text('No hay rutas disponibles'),
                    );
                  }

                  return DropdownButtonFormField<RutaModel>(
                    decoration: const InputDecoration(
                      labelText: 'Ruta',
                      border: OutlineInputBorder(),
                    ),
                    value: _rutaSeleccionada ?? rutas.first,
                    items: rutas.map((ruta) {
                      return DropdownMenuItem(
                        value: ruta,
                        child: Text(ruta.nombre),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _rutaSeleccionada = value;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _guardarPulperia,
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