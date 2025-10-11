import 'package:flutter/foundation.dart';
import '../models/producto_model.dart';
import '../repositories/producto_repository.dart';

class ProductoProvider with ChangeNotifier {
  ProductoRepository _repository;
  List<ProductoModel> _productosOriginal = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  ProductoProvider({required ProductoRepository repository})
      : _repository = repository {
    _cargarProductos();
  }

  // Getters
  List<ProductoModel> get productos {
    if (_searchQuery.isEmpty) return _productosOriginal;
    return _productosOriginal
        .where((producto) =>
        producto.nombre.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;

  void updateSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  ProductoProvider copyWith(ProductoRepository repository) {
    return ProductoProvider(repository: repository)
      .._productosOriginal = _productosOriginal
      .._isLoading = _isLoading
      .._error = _error
      .._searchQuery = _searchQuery;
  }

  // Método para actualizar el repository
  ProductoProvider updateRepository(ProductoRepository repository) {
    _repository = repository;
    _cargarProductos();
    return this;
  }

  Future<void> _cargarProductos() async {
    if (!_isLoading) {
      await loadProductos();
    }
  }

  Future<void> loadProductos() async {
    try {
      _setLoading(true);
      // Cargar productos locales primero
      _productosOriginal = await _repository.getProductosLocales();
      notifyListeners();

      // Intentar sincronizar sin lanzar excepciones
      if (!_isLoading) {
        try {
          await _repository.syncProductos();
          // Recargar productos después de sincronizar
          _productosOriginal = await _repository.getProductosLocales();
          notifyListeners();
        } catch (e) {
          print('Error en sincronización: $e');
          // No mostrar error si tenemos productos locales
          if (_productosOriginal.isEmpty) {
            _error = 'Error al sincronizar: $e';
          }
        }
      }
    } catch (e) {
      _error = e.toString();
      print('Error al cargar productos: $_error');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addProducto(ProductoModel producto) async {
    try {
      _setLoading(true);
      final newProducto = await _repository.createProducto(producto);
      _productosOriginal.add(newProducto);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('Error al agregar producto: $_error');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProducto(ProductoModel producto) async {
    try {
      _setLoading(true);
      final productoActualizado = await _repository.updateProducto(producto);
      final index = _productosOriginal.indexWhere((p) => p.id == productoActualizado.id);
      if (index != -1) {
        _productosOriginal[index] = productoActualizado;
      }
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('Error al actualizar producto: $_error');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteProducto(int id) async {
    try {
      _setLoading(true);
      await _repository.deleteProducto(id);
      _productosOriginal.removeWhere((p) => p.id == id);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('Error al eliminar producto: $_error');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> syncProductos() async {
    try {
      _setLoading(true);
      await _repository.syncProductos();
      // Después de sincronizar, cargar productos locales
      _productosOriginal = await _repository.getProductosLocales();
      _error = null;
      notifyListeners();
    } catch (e) {
      // Si hay error en la sincronización pero tenemos productos locales,
      // no mostramos el error
      if (_productosOriginal.isEmpty) {
        _error = e.toString();
      }
      print('Error al sincronizar productos: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}