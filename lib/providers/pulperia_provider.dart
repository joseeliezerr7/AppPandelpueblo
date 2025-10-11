import 'package:flutter/foundation.dart';
import 'package:pandelpueblo/providers/ruta_provider.dart';
import '../models/pulperia_model.dart';
import '../repositories/pulperia_repository.dart';
import '../services/database_helper.dart';

class PulperiaProvider with ChangeNotifier {
  bool _disposed = false;
  final PulperiaRepository _repository;
  final RutaProvider _rutaProvider;
  List<PulperiaModel> _pulperias = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  PulperiaProvider({
    required PulperiaRepository repository,
    required RutaProvider rutaProvider,
  }) : _repository = repository,
        _rutaProvider = rutaProvider {
    loadPulperias();  // Cargar datos iniciales
  }

  List<PulperiaModel> get pulperias => _pulperias;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<PulperiaModel> get pulperiasFiltradas {
    if (_searchQuery.isEmpty) return _pulperias;
    return _pulperias
        .where((pulperia) =>
        pulperia.nombre.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  void updateSearch(String query) {
    if (_disposed) return;
    _searchQuery = query;
    _safeNotifyListeners();
  }

  void _setLoading(bool value) {
    if (_disposed) return;
    _isLoading = value;
    _safeNotifyListeners();
  }

  PulperiaProvider copyWith(PulperiaRepository repository) {
    return PulperiaProvider(
      repository: repository,
      rutaProvider: _rutaProvider,
    ).._pulperias = _pulperias
      .._isLoading = _isLoading
      .._error = _error
      .._searchQuery = _searchQuery;
  }

  Future<void> loadPulperias() async {
    if (_disposed) return;
    try {
      _setLoading(true);
      _error = null;
      _pulperias = await _repository.getPulperiasLocales();
      _safeNotifyListeners();
    } catch (e) {
      if (!_disposed) {
        _error = 'Error al cargar pulperías: $e';
        print(_error);
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addPulperia(PulperiaModel pulperia) async {
    if (_disposed) return;
    try {
      _setLoading(true);
      await _repository.createPulperia(pulperia);
      if (!_disposed) {
        await loadPulperias();
        _error = null;
      }
    } catch (e) {
      if (!_disposed) {
        _error = 'Error al añadir pulpería: $e';
        print(_error);
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updatePulperia(PulperiaModel pulperia) async {
    if (_disposed) return;
    try {
      _setLoading(true);
      await _repository.updatePulperia(pulperia);
      if (!_disposed) {
        await loadPulperias();
        _error = null;
      }
    } catch (e) {
      if (!_disposed) {
        _error = 'Error al actualizar pulpería: $e';
        print(_error);
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deletePulperia(int id) async {
    if (_disposed) return;
    try {
      _setLoading(true);
      await _repository.deletePulperia(id);
      if (!_disposed) {
        await loadPulperias();
        _error = null;
      }
    } catch (e) {
      if (!_disposed) {
        _error = 'Error al eliminar pulpería: $e';
        print(_error);
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> syncPulperias() async {
    if (_disposed) return;
    try {
      _setLoading(true);
      _error = null;

      await _rutaProvider.syncRutas();

      final db = await DatabaseHelper.instance.database;
      final rutasLocales = await db.query('rutas', columns: ['id', 'servidorId']);

      await _repository.syncPulperias(rutasLocales);

      if (!_disposed) {
        await loadPulperias();
      }
    } catch (e) {
      if (!_disposed) {
        _error = 'Error al sincronizar pulperías: $e';
        print(_error);
        try {
          await loadPulperias();
        } catch (loadError) {
          print('Error al cargar datos locales: $loadError');
        }
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  bool hayCambiosPendientes() {
    return _pulperias.any((pulperia) => !pulperia.sincronizado);
  }

  int getCambiosPendientes() {
    return _pulperias.where((pulperia) => !pulperia.sincronizado).length;
  }

  void clearError() {
    if (_disposed) return;
    _error = null;
    _safeNotifyListeners();
  }

  Future<void> refresh() async {
    if (_disposed) return;
    try {
      await syncPulperias();
    } catch (e) {
      if (!_disposed) {
        _error = 'Error al refrescar datos: $e';
        print(_error);
      }
    }
  }
}