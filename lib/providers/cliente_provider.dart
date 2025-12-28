import 'package:flutter/foundation.dart';
import '../models/cliente_model.dart';
import '../repositories/cliente_repository.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';

class ClienteProvider with ChangeNotifier {
  final ClienteRepository _repository;

  ClienteProvider(ApiService apiService, ConnectivityService connectivityService)
      : _repository = ClienteRepository(apiService, connectivityService);

  List<ClienteModel> _clientes = [];
  List<ClienteModel> _clientesFiltrados = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<ClienteModel> get clientes => _clientes;
  List<ClienteModel> get clientesFiltrados => _clientesFiltrados;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Cargar clientes
  Future<void> loadClientes() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _clientes = await _repository.getClientesLocales();
      _aplicarFiltro();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cargar clientes por pulpería
  Future<void> loadClientesPorPulperia(int pulperiaId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _clientes = await _repository.getClientesPorPulperia(pulperiaId);
      _aplicarFiltro();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cargar clientes por ruta
  Future<List<ClienteModel>> loadClientesPorRuta(int rutaId) async {
    try {
      return await _repository.getClientesPorRuta(rutaId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Agregar cliente
  Future<void> addCliente(ClienteModel cliente) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.createCliente(cliente);
      await loadClientes();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Actualizar cliente
  Future<void> updateCliente(ClienteModel cliente) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.updateClienteLocal(cliente);
      await loadClientes();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Eliminar cliente
  Future<void> deleteCliente(int id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.deleteClienteLocal(id);
      await loadClientes();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Sincronizar con servidor
  Future<void> syncClientes() async {
    try {
      await _repository.syncClientes();
      await loadClientes();
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
      _clientesFiltrados = List.from(_clientes);
    } else {
      _clientesFiltrados = _clientes.where((cliente) {
        return cliente.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            cliente.telefono.contains(_searchQuery) ||
            cliente.direccion.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
  }

  // Verificar si hay cambios pendientes
  bool hayCambiosPendientes() {
    return _clientes.any((c) => !c.sincronizado);
  }

  // Obtener cantidad de cambios pendientes
  int getCambiosPendientes() {
    return _clientes.where((c) => !c.sincronizado).length;
  }
}
