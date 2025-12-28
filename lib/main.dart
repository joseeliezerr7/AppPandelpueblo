import 'package:flutter/material.dart';
import 'package:pandelpueblo/providers/pulperia_provider.dart';
import 'package:pandelpueblo/repositories/pulperia_repository.dart';
import 'package:pandelpueblo/screens/Auth/home_screen.dart';
import 'package:pandelpueblo/screens/Pulperias/pulperias_screen.dart';
import 'package:pandelpueblo/screens/Rutas/RutasScreen.dart';
import 'package:provider/provider.dart';
import 'screens/Categorias/categorias_screen.dart';
import 'services/api_service.dart';
import 'services/connectivity_service.dart';
import 'services/database_helper.dart';
import 'services/sync_service.dart';
import 'providers/sync_provider.dart';
import 'repositories/producto_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/categoria_repository.dart';
import 'repositories/ruta_repository.dart';
import 'repositories/cliente_repository.dart';
import 'repositories/pedido_repository.dart';
import 'repositories/user_repository.dart';
import 'repositories/cronograma_visita_repository.dart';
import 'repositories/visita_cliente_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/producto_provider.dart';
import 'providers/categoria_provider.dart';
import 'providers/ruta_provider.dart';
import 'providers/cliente_provider.dart';
import 'providers/pedido_provider.dart';
import 'providers/user_provider.dart';
import 'providers/cronograma_visita_provider.dart';
import 'providers/visita_cliente_provider.dart';
import 'screens/login_screen.dart';
import 'screens/Productos/productos_screen.dart';
import 'screens/Productos/producto_form_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final dbHelper = DatabaseHelper.instance;
    // await dbHelper.resetDatabase(); // Comentado - no borrar datos en cada inicio
    await dbHelper.checkDatabaseAccess();
    print('Base de datos inicializada correctamente');
  } catch (e) {
    print('Error inicializando base de datos: $e');
  }

  const serverUrl = 'http://10.0.2.2:8000';
  final apiService = ApiService(baseUrl: serverUrl);
  final connectivityService = ConnectivityService(serverUrl: serverUrl);

  runApp(
    MultiProvider(
      providers: [
        // Servicios base
        Provider<DatabaseHelper>.value(value: DatabaseHelper.instance),
        Provider<ApiService>.value(value: apiService),
        Provider<ConnectivityService>.value(value: connectivityService),


        // Repositories
        ProxyProvider<ApiService, AuthRepository>(
          update: (context, api, previous) =>
              AuthRepository(api, connectivityService),
        ),

        ProxyProvider3<ApiService, DatabaseHelper, ConnectivityService, ProductoRepository>(
          update: (context, api, dbHelper, connectivity, previous) =>
              ProductoRepository(api, connectivity),
        ),

        ProxyProvider3<ApiService, DatabaseHelper, ConnectivityService, CategoriaRepository>(
          update: (context, api, dbHelper, connectivity, previous) =>
              CategoriaRepository(api, connectivity),
        ),

        ProxyProvider3<ApiService, DatabaseHelper, ConnectivityService, RutaRepository>(
          update: (context, api, dbHelper, connectivity, previous) =>
              RutaRepository(api, connectivity),
        ),
        ProxyProvider3<ApiService, DatabaseHelper, ConnectivityService, PulperiaRepository>(
          update: (context, api, dbHelper, connectivity, previous) =>
              PulperiaRepository(api, connectivity),
        ),

        ProxyProvider2<ApiService, ConnectivityService, UserRepository>(
          update: (context, api, connectivity, previous) =>
              UserRepository(api, connectivity),
        ),

        ProxyProvider2<ApiService, ConnectivityService, ClienteRepository>(
          update: (context, api, connectivity, previous) =>
              ClienteRepository(api, connectivity),
        ),

        ProxyProvider2<ApiService, ConnectivityService, PedidoRepository>(
          update: (context, api, connectivity, previous) =>
              PedidoRepository(api, connectivity),
        ),

        ProxyProvider2<ApiService, ConnectivityService, CronogramaVisitaRepository>(
          update: (context, api, connectivity, previous) =>
              CronogramaVisitaRepository(api, connectivity),
        ),

        ProxyProvider2<ApiService, ConnectivityService, VisitaClienteRepository>(
          update: (context, api, connectivity, previous) =>
              VisitaClienteRepository(api, connectivity),
        ),

        // Providers
        ChangeNotifierProxyProvider<AuthRepository, AuthProvider>(
          create: (context) => AuthProvider(
            authRepository: context.read<AuthRepository>(),
            connectivityService: connectivityService,
          ),
          update: (context, authRepository, previous) =>
          previous?.copyWith(authRepository) ??
              AuthProvider(
                authRepository: authRepository,
                connectivityService: connectivityService,
              ),
        ),

        ChangeNotifierProxyProvider<ProductoRepository, ProductoProvider>(
          create: (context) => ProductoProvider(
            repository: context.read<ProductoRepository>(),
          ),
          update: (context, repository, previous) =>
          previous?.copyWith(repository) ??
              ProductoProvider(
                repository: repository,
              ),
        ),

        ChangeNotifierProxyProvider<CategoriaRepository, CategoriaProvider>(
          create: (context) => CategoriaProvider(
            repository: context.read<CategoriaRepository>(),
          ),
          update: (context, repository, previous) =>
          previous?.copyWith(repository) ??
              CategoriaProvider(
                repository: repository,
              ),
        ),

        ChangeNotifierProxyProvider<RutaRepository, RutaProvider>(
          create: (context) => RutaProvider(
            repository: context.read<RutaRepository>(),
          ),
          update: (context, repository, previous) =>
          previous?.copyWith(repository) ??
              RutaProvider(
                repository: repository,
              ),
        ),
    ChangeNotifierProxyProvider2<PulperiaRepository, RutaProvider, PulperiaProvider>(
        create: (context) => PulperiaProvider(
          repository: context.read<PulperiaRepository>(),
          rutaProvider: context.read<RutaProvider>(),
        ),
        update: (context, repository, rutaProvider, previous) =>
        previous?.copyWith(repository) ??
            PulperiaProvider(
              repository: repository,
              rutaProvider: rutaProvider,
            ),
    ),

        ChangeNotifierProxyProvider<UserRepository, UserProvider>(
          create: (context) => UserProvider(
            context.read<UserRepository>(),
          ),
          update: (context, repository, previous) =>
              previous ?? UserProvider(repository),
        ),

        ChangeNotifierProxyProvider2<ApiService, ConnectivityService, ClienteProvider>(
          create: (context) => ClienteProvider(
            context.read<ApiService>(),
            context.read<ConnectivityService>(),
          ),
          update: (context, apiService, connectivityService, previous) =>
              previous ?? ClienteProvider(apiService, connectivityService),
        ),

        ChangeNotifierProxyProvider2<ApiService, ConnectivityService, PedidoProvider>(
          create: (context) => PedidoProvider(
            context.read<ApiService>(),
            context.read<ConnectivityService>(),
          ),
          update: (context, apiService, connectivityService, previous) =>
              previous ?? PedidoProvider(apiService, connectivityService),
        ),

        ChangeNotifierProxyProvider<CronogramaVisitaRepository, CronogramaVisitaProvider>(
          create: (context) => CronogramaVisitaProvider(
            context.read<CronogramaVisitaRepository>(),
          ),
          update: (context, repository, previous) =>
              previous ?? CronogramaVisitaProvider(repository),
        ),

        ChangeNotifierProxyProvider<VisitaClienteRepository, VisitaClienteProvider>(
          create: (context) => VisitaClienteProvider(
            context.read<VisitaClienteRepository>(),
          ),
          update: (context, repository, previous) =>
              previous ?? VisitaClienteProvider(repository),
        ),

        // Sync Service - debe ir al final después de todos los providers
        ProxyProvider6<RutaProvider, CategoriaProvider, ProductoProvider, PulperiaProvider, ClienteProvider, PedidoProvider, SyncService>(
          update: (context, rutaProvider, categoriaProvider, productoProvider, pulperiaProvider, clienteProvider, pedidoProvider, previous) =>
            previous ?? SyncService(
              rutaProvider: rutaProvider,
              categoriaProvider: categoriaProvider,
              productoProvider: productoProvider,
              pulperiaProvider: pulperiaProvider,
              clienteProvider: clienteProvider,
              pedidoProvider: pedidoProvider,
            ),
          dispose: (context, syncService) => syncService.dispose(),
        ),

        ChangeNotifierProxyProvider<SyncService, SyncProvider>(
          create: (context) => SyncProvider(context.read<SyncService>()),
          update: (context, syncService, previous) =>
            previous ?? SyncProvider(syncService),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pan del Pueblo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthenticationWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/productos': (context) => const ProductosScreen(),
        '/productos/form': (context) => const ProductoFormScreen(
          producto: null,
          esNuevo: true,
        ),
        '/categorias': (context) => const CategoriasScreen(),
        '/rutas': (context) => const RutasScreen(),
        '/pulperias': (context) => const PulperiasScreen(),
      },
    );
  }
}

class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({super.key});

  @override
  State<AuthenticationWrapper> createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  bool _hasSyncedOnConnect = false;

  Future<void> _checkConnectivityAndSync() async {
    if (!mounted) return;

    final connectivityService = context.read<ConnectivityService>();
    final hasConnection = await connectivityService.hasConnection();

    if (!_hasSyncedOnConnect && hasConnection && mounted) {
      _hasSyncedOnConnect = true;
      try {
        final productoProvider = context.read<ProductoProvider>();
        final categoriaProvider = context.read<CategoriaProvider>();
        final rutaProvider = context.read<RutaProvider>();
        final pulperiaProvider = context.read<PulperiaProvider>();
        final userProvider = context.read<UserProvider>();
        final authProvider = context.read<AuthProvider>();

        if (authProvider.isAuthenticated) {
          print('Iniciando sincronización completa de datos...');

          // Sincronizar todos los datos en paralelo
          await Future.wait([
            productoProvider.syncProductos(),
            categoriaProvider.syncCategorias(),
            rutaProvider.syncRutas(),
            pulperiaProvider.syncPulperias(),
            userProvider.cargarUsuarios(forzarSync: true),
            authProvider.syncUserData(),
          ]);

          if (!mounted) return;

          print('Sincronización completada exitosamente');
          print('Productos: ${productoProvider.productos.length}');
          print('Categorías: ${categoriaProvider.categorias.length}');
          print('Rutas: ${rutaProvider.rutas.length}');
          print('Pulperías: ${pulperiaProvider.pulperias.length}');
          print('Usuarios: ${userProvider.usuarios.length}');

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Datos sincronizados correctamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        print('Error en la sincronización: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en la sincronización: $e'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        _hasSyncedOnConnect = false;
      }
    } else if (!hasConnection) {
      _hasSyncedOnConnect = false;

      // Cargar datos locales aunque no haya conexión
      try {
        final productoProvider = context.read<ProductoProvider>();
        final categoriaProvider = context.read<CategoriaProvider>();
        final rutaProvider = context.read<RutaProvider>();
        final pulperiaProvider = context.read<PulperiaProvider>();
        final userProvider = context.read<UserProvider>();

        print('Sin conexión - cargando datos locales...');
        await Future.wait([
          productoProvider.loadProductos(),
          categoriaProvider.loadCategorias(),
          rutaProvider.loadRutas(),
          pulperiaProvider.loadPulperias(),
          userProvider.cargarUsuarios(forzarSync: false),
        ]);

        print('Datos locales cargados');
      } catch (e) {
        print('Error cargando datos locales: $e');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkConnectivityAndSync();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkConnectivityAndSync();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (!authProvider.isInitialized) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return authProvider.isAuthenticated
            ? const HomeScreen()
            : const LoginScreen();
      },
    );
  }
}