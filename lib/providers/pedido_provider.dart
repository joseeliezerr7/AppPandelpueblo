import 'package:flutter/foundation.dart';
import '../models/pedido_model.dart';
import '../repositories/pedido_repository.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';

class PedidoProvider with ChangeNotifier {
  final PedidoRepository _repository;

  PedidoProvider(ApiService apiService, ConnectivityService connectivityService)
      : _repository = PedidoRepository(apiService, connectivityService);

  List<PedidoModel> _pedidos = [];
  List<PedidoModel> _pedidosFiltrados = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<PedidoModel> get pedidos => _pedidos;
  List<PedidoModel> get pedidosFiltrados => _pedidosFiltrados;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Cargar todos los pedidos
  Future<void> loadPedidos() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _pedidos = await _repository.getPedidosLocales();
      _aplicarFiltro();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cargar pedidos por cliente
  Future<List<PedidoModel>> loadPedidosPorCliente(int clienteId) async {
    try {
      return await _repository.getPedidosPorCliente(clienteId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Cargar pedidos por pulpería
  Future<List<PedidoModel>> loadPedidosPorPulperia(int pulperiaId) async {
    try {
      return await _repository.getPedidosPorPulperia(pulperiaId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Agregar pedido
  Future<PedidoModel> addPedido(PedidoModel pedido, List<DetallePedidoModel> detalles) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final pedidoCreado = await _repository.createPedido(pedido, detalles);

      // NO cargar pedidos locales aquí porque:
      // - Si hay conexión, el pedido se creó en servidor y NO está en BD local
      // - Si no hay conexión, el pedido está en BD local pero será sincronizado después
      // await loadPedidos();

      _isLoading = false;
      notifyListeners();

      return pedidoCreado;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Actualizar pedido
  Future<void> updatePedido(PedidoModel pedido, List<DetallePedidoModel> detalles) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.updatePedidoLocal(pedido, detalles);
      await loadPedidos();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Eliminar pedido
  Future<void> deletePedido(int id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.deletePedidoLocal(id);
      await loadPedidos();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Sincronizar con servidor
  Future<void> syncPedidos() async {
    try {
      await _repository.syncPedidos();
      await loadPedidos();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Actualizar búsqueda
  void updateSearch(String query) {
    _searchQuery = query;
    _aplicarFiltro();
    notifyListeners();
  }

  // Aplicar filtro de búsqueda
  void _aplicarFiltro() {
    if (_searchQuery.isEmpty) {
      _pedidosFiltrados = List.from(_pedidos);
    } else {
      _pedidosFiltrados = _pedidos.where((pedido) {
        final nombreCliente = pedido.nombreCliente?.toLowerCase() ?? '';
        final nombrePulperia = pedido.nombrePulperia?.toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();

        return nombreCliente.contains(query) || nombrePulperia.contains(query);
      }).toList();
    }
  }

  // Verificar si hay cambios pendientes
  bool hayCambiosPendientes() {
    return _pedidos.any((p) => !p.sincronizado);
  }

  // Obtener cantidad de cambios pendientes
  int getCambiosPendientes() {
    return _pedidos.where((p) => !p.sincronizado).length;
  }
}
