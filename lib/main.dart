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
import 'repositories/producto_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/categoria_repository.dart';
import 'repositories/ruta_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/producto_provider.dart';
import 'providers/categoria_provider.dart';
import 'providers/ruta_provider.dart';
import 'screens/login_screen.dart';
import 'screens/Productos/productos_screen.dart';
import 'screens/Productos/producto_form_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.resetDatabase();
    await dbHelper.checkDatabaseAccess();
    print('Base de datos inicializada correctamente');
  } catch (e) {
    print('Error inicializando base de datos: $e');
  }

  final apiService = ApiService(baseUrl: 'http://10.0.2.2:8000');
  final connectivityService = ConnectivityService();

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
        final authProvider = context.read<AuthProvider>();

        if (authProvider.isAuthenticated) {
          await Future.wait([
            productoProvider.syncProductos(),
            categoriaProvider.syncCategorias(),
            rutaProvider.syncRutas(),
            authProvider.syncUserData(),
          ]);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sincronización completada'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en la sincronización: $e'),
            backgroundColor: Colors.red,
          ),
        );
        _hasSyncedOnConnect = false;
      }
    } else if (!hasConnection) {
      _hasSyncedOnConnect = false;
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