import 'package:flutter/foundation.dart';
import '../models/ruta_model.dart';
import '../repositories/ruta_repository.dart';

class RutaProvider with ChangeNotifier {
  final RutaRepository _repository;
  List<RutaModel> _rutas = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  RutaProvider({
    required RutaRepository repository,
  }) : _repository = repository;

  List<RutaModel> get rutas => _rutas;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<RutaModel> get rutasFiltradas {
    if (_searchQuery.isEmpty) return _rutas;
    return _rutas
        .where((ruta) =>
        ruta.nombre.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void updateSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  RutaProvider copyWith(RutaRepository repository) {
    return RutaProvider(repository: repository)
      .._rutas = _rutas
      .._isLoading = _isLoading
      .._error = _error
      .._searchQuery = _searchQuery;
  }

  Future<void> loadRutas() async {
    try {
      _setLoading(true);
      _error = null;
      _rutas = await _repository.getRutasLocales();
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar rutas: $e';
      print(_error);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addRuta(String nombre) async {
    try {
      _setLoading(true);
      final ruta = RutaModel(nombre: nombre);
      await _repository.createRuta(ruta);
      await loadRutas();
      _error = null;
    } catch (e) {
      _error = 'Error al añadir ruta: $e';
      print(_error);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateRuta(RutaModel ruta) async {
    try {
      _setLoading(true);
      await _repository.updateRuta(ruta);
      await loadRutas();
      _error = null;
    } catch (e) {
      _error = 'Error al actualizar ruta: $e';
      print(_error);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteRuta(int id) async {
    try {
      _setLoading(true);
      await _repository.deleteRuta(id);
      await loadRutas();
      _error = null;
    } catch (e) {
      _error = 'Error al eliminar ruta: $e';
      print(_error);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> syncRutas() async {
    try {
      _setLoading(true);
      _error = null;
      await _repository.syncRutas();
      await loadRutas();
    } catch (e) {
      _error = 'Error al sincronizar rutas: $e';
      print(_error);
      await loadRutas();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  bool hayCambiosPendientes() {
    return _rutas.any((ruta) => !ruta.sincronizado);
  }

  int getCambiosPendientes() {
    return _rutas.where((ruta) => !ruta.sincronizado).length;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    try {
      await syncRutas();
    } catch (e) {
      _error = 'Error al refrescar datos: $e';
      print(_error);
    }
  }
}