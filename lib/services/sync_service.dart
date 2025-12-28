import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../providers/ruta_provider.dart';
import '../providers/categoria_provider.dart';
import '../providers/producto_provider.dart';
import '../providers/pulperia_provider.dart';
import '../providers/cliente_provider.dart';
import '../providers/pedido_provider.dart';

class SyncService {
  final RutaProvider rutaProvider;
  final CategoriaProvider categoriaProvider;
  final ProductoProvider productoProvider;
  final PulperiaProvider pulperiaProvider;
  final ClienteProvider clienteProvider;
  final PedidoProvider pedidoProvider;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = false;
  bool _isSyncing = false;
  DateTime? _lastSync;

  SyncService({
    required this.rutaProvider,
    required this.categoriaProvider,
    required this.productoProvider,
    required this.pulperiaProvider,
    required this.clienteProvider,
    required this.pedidoProvider,
  });

  /// Iniciar el listener de conectividad
  void startListening() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _handleConnectivityChange(results);
      },
    );

    // Verificar estado inicial
    _checkInitialConnectivity();
  }

  /// Detener el listener
  void stopListening() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  /// Verificar conectividad inicial
  Future<void> _checkInitialConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      _handleConnectivityChange(results);
    } catch (e) {
      print('Error verificando conectividad inicial: $e');
    }
  }

  /// Manejar cambios de conectividad
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = results.any((result) =>
      result != ConnectivityResult.none
    );

    print('Estado de conectividad cambió: ${_isOnline ? "ONLINE" : "OFFLINE"}');

    // Si acabamos de conectarnos, sincronizar
    if (!wasOnline && _isOnline) {
      print('Conexión restaurada - iniciando sincronización automática');
      _autoSync();
    }
  }

  /// Sincronización automática cuando se restaura la conexión
  Future<void> _autoSync() async {
    if (_isSyncing) {
      print('Ya hay una sincronización en progreso');
      return;
    }

    // Evitar sincronizaciones muy frecuentes (mínimo 30 segundos entre sync)
    if (_lastSync != null) {
      final timeSinceLastSync = DateTime.now().difference(_lastSync!);
      if (timeSinceLastSync.inSeconds < 30) {
        print('Sincronización muy reciente, esperando...');
        return;
      }
    }

    _isSyncing = true;
    _lastSync = DateTime.now();

    try {
      print('Iniciando sincronización automática...');

      // Sincronizar en orden: rutas -> categorías -> productos -> pulperías -> clientes -> pedidos
      await rutaProvider.syncRutas();
      print('✓ Rutas sincronizadas');

      await Future.delayed(const Duration(milliseconds: 500));
      await categoriaProvider.syncCategorias();
      print('✓ Categorías sincronizadas');

      await Future.delayed(const Duration(milliseconds: 500));
      await productoProvider.syncProductos();
      print('✓ Productos sincronizados');

      await Future.delayed(const Duration(milliseconds: 500));
      await pulperiaProvider.syncPulperias();
      print('✓ Pulperías sincronizadas');

      await Future.delayed(const Duration(milliseconds: 500));
      await clienteProvider.syncClientes();
      print('✓ Clientes sincronizados');

      await Future.delayed(const Duration(milliseconds: 500));
      await pedidoProvider.syncPedidos();
      print('✓ Pedidos sincronizados');

      print('Sincronización automática completada exitosamente');
    } catch (e) {
      print('Error en sincronización automática: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Forzar sincronización manual
  Future<void> forceSync() async {
    if (!_isOnline) {
      throw Exception('No hay conexión a internet');
    }

    return _autoSync();
  }

  /// Verificar si hay cambios pendientes de sincronizar
  bool hasPendingChanges() {
    return rutaProvider.hayCambiosPendientes() ||
           categoriaProvider.hayCambiosPendientes() ||
           productoProvider.hayCambiosPendientes() ||
           pulperiaProvider.hayCambiosPendientes() ||
           clienteProvider.hayCambiosPendientes() ||
           pedidoProvider.hayCambiosPendientes();
  }

  /// Obtener contador total de cambios pendientes
  int getPendingChangesCount() {
    int total = 0;
    total += rutaProvider.getCambiosPendientes();
    total += categoriaProvider.getCambiosPendientes();
    total += productoProvider.getCambiosPendientes();
    total += pulperiaProvider.getCambiosPendientes();
    total += clienteProvider.getCambiosPendientes();
    total += pedidoProvider.getCambiosPendientes();
    return total;
  }

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSync => _lastSync;

  void dispose() {
    stopListening();
  }
}
