import 'package:flutter/foundation.dart';
import '../models/categoria_model.dart';
import '../repositories/categoria_repository.dart';

class CategoriaProvider with ChangeNotifier {
  final CategoriaRepository _repository;
  List<CategoriaModel> _categorias = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  CategoriaProvider({
    required CategoriaRepository repository,
  }) : _repository = repository;

  // Getters
  List<CategoriaModel> get categorias => _categorias;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<CategoriaModel> get categoriasFiltradas {
    if (_searchQuery.isEmpty) return _categorias;
    return _categorias
        .where((categoria) =>
        categoria.nombre.toLowerCase().contains(_searchQuery.toLowerCase()))
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

  CategoriaProvider copyWith(CategoriaRepository repository) {
    return CategoriaProvider(repository: repository)
      .._categorias = _categorias
      .._isLoading = _isLoading
      .._error = _error
      .._searchQuery = _searchQuery;
  }

  Future<void> loadCategorias() async {
    try {
      _setLoading(true);
      _error = null;
      _categorias = await _repository.getCategoriasLocales();
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar categorías: $e';
      print(_error);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addCategoria(String nombre) async {
    try {
      _setLoading(true);
      final categoria = CategoriaModel(nombre: nombre);
      await _repository.createCategoria(categoria);
      await loadCategorias();
      _error = null;
    } catch (e) {
      _error = 'Error al añadir categoría: $e';
      print(_error);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateCategoria(CategoriaModel categoria) async {
    try {
      _setLoading(true);
      await _repository.updateCategoria(categoria);
      await loadCategorias();
      _error = null;
    } catch (e) {
      _error = 'Error al actualizar categoría: $e';
      print(_error);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteCategoria(int id) async {
    try {
      _setLoading(true);
      await _repository.deleteCategoria(id);
      // Eliminar inmediatamente de la lista local
      _categorias.removeWhere((c) => c.id == id);
      notifyListeners();
      // Recargar para asegurar consistencia
      await loadCategorias();
    } catch (e) {
      _error = 'Error al eliminar categoría: $e';
      print(_error);
      // Recargar en caso de error
      await loadCategorias();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> syncCategorias() async {
    try {
      _setLoading(true);
      _error = null;
      await _repository.syncCategorias();
      await loadCategorias();
    } catch (e) {
      _error = 'Error al sincronizar categorías: $e';
      print(_error);
      try {
        await loadCategorias();
      } catch (loadError) {
        print('Error al cargar datos locales: $loadError');
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Método para verificar si hay cambios pendientes
  bool hayCambiosPendientes() {
    return _categorias.any((categoria) => !categoria.sincronizado);
  }

  // Método para obtener el número de cambios pendientes
  int getCambiosPendientes() {
    return _categorias.where((categoria) => !categoria.sincronizado).length;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    try {
      await syncCategorias();
    } catch (e) {
      _error = 'Error al refrescar datos: $e';
      print(_error);
    }
  }

  // Método para forzar una recarga de datos
  Future<void> forceReload() async {
    try {
      await loadCategorias();
    } catch (e) {
      print('Error en forceReload: $e');
    }
  }
}