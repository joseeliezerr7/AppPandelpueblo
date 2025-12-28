import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/categoria_provider.dart';
import '../../providers/producto_provider.dart';
import '../../providers/ruta_provider.dart';
import '../../providers/pulperia_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/menu_card.dart';
import '../Categorias/categorias_screen.dart';
import '../Productos/productos_screen.dart';
import '../Rutas/RutasScreen.dart';
import '../Pulperias/pulperias_screen.dart';
import '../Rutas/MisRutasScreen.dart';
import '../Pedidos/pedidos_screen.dart';
import '../Empleados/asignar_ruta_screen.dart';
import '../Usuarios/usuarios_screen.dart';
import '../login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _syncAllData() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sincronizando datos...'),
          duration: Duration(seconds: 2),
        ),
      );

      await Future.wait([
        context.read<RutaProvider>().syncRutas(),
        Future.delayed(const Duration(seconds: 1))
            .then((_) => context.read<CategoriaProvider>().syncCategorias()),
        Future.delayed(const Duration(seconds: 2))
            .then((_) => context.read<ProductoProvider>().syncProductos()),
        Future.delayed(const Duration(seconds: 3))
            .then((_) => context.read<PulperiaProvider>().syncPulperias()),
      ]);

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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pan del Pueblo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _syncAllData,
            tooltip: 'Sincronizar todos los datos',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 35),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user?.nombre ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    user?.correoElectronico ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // OPERACIONES DIARIAS
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'OPERACIONES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.map_outlined, color: Colors.blue.shade700),
              title: const Text('Mis Rutas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MisRutasScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.shopping_cart_outlined, color: Colors.orange.shade700),
              title: const Text('Pedidos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PedidosScreen()),
                );
              },
            ),

            // GESTIÓN
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'GESTIÓN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.store_outlined, color: Colors.purple.shade700),
              title: const Text('Pulperías'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PulperiasScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.inventory_2_outlined, color: Colors.green.shade700),
              title: const Text('Productos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProductosScreen()),
                );
              },
            ),

            // ADMINISTRACIÓN (solo admin)
            if (user?.permiso == 'admin') ...[
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'ADMINISTRACIÓN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.route_outlined, color: Colors.teal.shade700),
                title: const Text('Rutas'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RutasScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.people_outline, color: Colors.indigo.shade700),
                title: const Text('Usuarios'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UsuariosScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.category_outlined, color: Colors.pink.shade700),
                title: const Text('Categorías'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CategoriasScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.assignment_ind_outlined, color: Colors.deepOrange.shade700),
                title: const Text('Asignar Rutas'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AsignarRutaScreen()),
                  );
                },
              ),
            ],
            const Divider(),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Cerrar Sesión'),
              onTap: () {
                context.read<AuthProvider>().logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            // Welcome Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, ${user?.nombre ?? ""}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bienvenido a Pan del Pueblo',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Menu Sections
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // SECCIÓN: OPERACIONES DIARIAS
                  const Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 12, top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.work_outline, size: 20, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          'OPERACIONES DIARIAS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      MenuCard(
                        title: 'Mis Rutas',
                        icon: Icons.map_outlined,
                        color: Colors.blue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MisRutasScreen()),
                          );
                        },
                      ),
                      MenuCard(
                        title: 'Pedidos',
                        icon: Icons.shopping_cart_outlined,
                        color: Colors.orange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PedidosScreen()),
                          );
                        },
                      ),
                    ],
                  ),

                  // SECCIÓN: GESTIÓN
                  const Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 12, top: 24),
                    child: Row(
                      children: [
                        Icon(Icons.business_center_outlined, size: 20, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          'GESTIÓN',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      MenuCard(
                        title: 'Pulperías',
                        icon: Icons.store_outlined,
                        color: Colors.purple,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PulperiasScreen()),
                          );
                        },
                      ),
                      MenuCard(
                        title: 'Productos',
                        icon: Icons.inventory_2_outlined,
                        color: Colors.green,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ProductosScreen()),
                          );
                        },
                      ),
                    ],
                  ),

                  // SECCIÓN: ADMINISTRACIÓN (solo para admin)
                  if (user?.permiso == 'admin') ...[
                    const Padding(
                      padding: EdgeInsets.only(left: 8, bottom: 12, top: 24),
                      child: Row(
                        children: [
                          Icon(Icons.admin_panel_settings_outlined, size: 20, color: Colors.grey),
                          SizedBox(width: 8),
                          Text(
                            'ADMINISTRACIÓN',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        MenuCard(
                          title: 'Rutas',
                          icon: Icons.route_outlined,
                          color: Colors.teal,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RutasScreen()),
                            );
                          },
                        ),
                        MenuCard(
                          title: 'Usuarios',
                          icon: Icons.people_outline,
                          color: Colors.indigo,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const UsuariosScreen()),
                            );
                          },
                        ),
                        MenuCard(
                          title: 'Categorías',
                          icon: Icons.category_outlined,
                          color: Colors.pink,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CategoriasScreen()),
                            );
                          },
                        ),
                        MenuCard(
                          title: 'Asignar Rutas',
                          icon: Icons.assignment_ind_outlined,
                          color: Colors.deepOrange,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AsignarRutaScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}