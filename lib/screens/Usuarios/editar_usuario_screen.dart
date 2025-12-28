import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';

class EditarUsuarioScreen extends StatefulWidget {
  final UserModel usuario;

  const EditarUsuarioScreen({Key? key, required this.usuario}) : super(key: key);

  @override
  State<EditarUsuarioScreen> createState() => _EditarUsuarioScreenState();
}

class _EditarUsuarioScreenState extends State<EditarUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _emailController;
  late TextEditingController _telefonoController;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late String _permisoSeleccionado;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _cambiarPassword = false;

  final List<Map<String, dynamic>> _permisos = [
    {'value': 'admin', 'label': 'Administrador', 'icon': Icons.admin_panel_settings, 'color': Colors.red},
    {'value': 'vendedor', 'label': 'Vendedor', 'icon': Icons.person_outline, 'color': Colors.blue},
    {'value': 'empleado', 'label': 'Empleado', 'icon': Icons.work_outline, 'color': Colors.green},
    {'value': 'usuario', 'label': 'Usuario', 'icon': Icons.person, 'color': Colors.orange},
  ];

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.usuario.nombre);
    _emailController = TextEditingController(text: widget.usuario.correoElectronico);
    _telefonoController = TextEditingController(text: widget.usuario.telefono);
    _permisoSeleccionado = widget.usuario.permiso;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _actualizarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userProvider = context.read<UserProvider>();

      await userProvider.actualizarUsuario(
        id: widget.usuario.id,
        nombre: _nombreController.text.trim(),
        email: _emailController.text.trim(),
        telefono: _telefonoController.text.trim(),
        permiso: _permisoSeleccionado,
        password: _cambiarPassword ? _passwordController.text : null,
        rutaId: widget.usuario.rutaId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar usuario: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Usuario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirmar = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirmar eliminación'),
                  content: Text('¿Estás seguro de eliminar a ${widget.usuario.nombre}?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Eliminar'),
                    ),
                  ],
                ),
              );

              if (confirmar == true && mounted) {
                try {
                  await context.read<UserProvider>().eliminarUsuario(widget.usuario.id);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${widget.usuario.nombre} eliminado'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context, true);
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
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Información del usuario
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Información básica',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Nombre
                            TextFormField(
                              controller: _nombreController,
                              decoration: const InputDecoration(
                                labelText: 'Nombre completo *',
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'El nombre es requerido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Email
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Correo electrónico *',
                                prefixIcon: Icon(Icons.email),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'El correo es requerido';
                                }
                                if (!value.contains('@')) {
                                  return 'Ingresa un correo válido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Teléfono
                            TextFormField(
                              controller: _telefonoController,
                              decoration: const InputDecoration(
                                labelText: 'Teléfono',
                                prefixIcon: Icon(Icons.phone),
                                border: OutlineInputBorder(),
                                hintText: '+505 0000-0000',
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 16),

                            // Permiso
                            DropdownButtonFormField<String>(
                              value: _permisoSeleccionado,
                              decoration: const InputDecoration(
                                labelText: 'Tipo de usuario *',
                                prefixIcon: Icon(Icons.badge),
                                border: OutlineInputBorder(),
                              ),
                              items: _permisos.map((permiso) {
                                return DropdownMenuItem(
                                  value: permiso['value'] as String,
                                  child: Row(
                                    children: [
                                      Icon(
                                        permiso['icon'] as IconData,
                                        color: permiso['color'] as Color,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(permiso['label'] as String),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _permisoSeleccionado = value!;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cambiar contraseña
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Cambiar contraseña',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Switch(
                                  value: _cambiarPassword,
                                  onChanged: (value) {
                                    setState(() {
                                      _cambiarPassword = value;
                                      if (!value) {
                                        _passwordController.clear();
                                        _confirmPasswordController.clear();
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),

                            if (_cambiarPassword) ...[
                              const SizedBox(height: 16),
                              const Text(
                                'Nueva contraseña',
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 8),

                              // Password
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Contraseña *',
                                  prefixIcon: const Icon(Icons.lock),
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                obscureText: _obscurePassword,
                                validator: (value) {
                                  if (_cambiarPassword) {
                                    if (value == null || value.isEmpty) {
                                      return 'La contraseña es requerida';
                                    }
                                    if (value.length < 6) {
                                      return 'La contraseña debe tener al menos 6 caracteres';
                                    }
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Confirmar Password
                              TextFormField(
                                controller: _confirmPasswordController,
                                decoration: InputDecoration(
                                  labelText: 'Confirmar contraseña *',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword = !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                ),
                                obscureText: _obscureConfirmPassword,
                                validator: (value) {
                                  if (_cambiarPassword) {
                                    if (value == null || value.isEmpty) {
                                      return 'Confirma la contraseña';
                                    }
                                    if (value != _passwordController.text) {
                                      return 'Las contraseñas no coinciden';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botón Guardar
                    ElevatedButton.icon(
                      onPressed: _actualizarUsuario,
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar Cambios'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
