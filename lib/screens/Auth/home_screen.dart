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
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Pedidos'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Clientes'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Productos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProductosScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.route),
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
              leading: const Icon(Icons.store),
              title: const Text('Pulperías'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PulperiasScreen()),
                );
              },
            ),
            if (user?.permiso == 'admin')
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Usuarios'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
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

            // Menu Grid
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.all(16),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  MenuCard(
                    title: 'Pedidos',
                    icon: Icons.shopping_cart,
                    color: AppTheme.pedidosColor,
                    onTap: () {},
                  ),
                  MenuCard(
                    title: 'Clientes',
                    icon: Icons.people,
                    color: AppTheme.clientesColor,
                    onTap: () {},
                  ),
                  MenuCard(
                    title: 'Productos',
                    icon: Icons.inventory_2_rounded,
                    color: AppTheme.productosColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProductosScreen()),
                      );
                    },
                  ),
                  MenuCard(
                    title: 'Rutas',
                    icon: Icons.route_rounded,
                    color: AppTheme.rutasColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RutasScreen()),
                      );
                    },
                  ),
                  MenuCard(
                    title: 'Pulperías',
                    icon: Icons.store_rounded,
                    color: AppTheme.pulperiasColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PulperiasScreen()),
                      );
                    },
                  ),
                  if (user?.permiso == 'admin')
                    MenuCard(
                      title: 'Categorías',
                      icon: Icons.category_rounded,
                      color: AppTheme.categoriasColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CategoriasScreen()),
                        );
                      },
                    ),
                  if (user?.permiso == 'admin')
                    MenuCard(
                      title: 'Usuarios',
                      icon: Icons.admin_panel_settings_rounded,
                      color: AppTheme.usuariosColor,
                      onTap: () {},
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}