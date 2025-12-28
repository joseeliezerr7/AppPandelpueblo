import 'package:flutter/foundation.dart';
import '../models/cronograma_visita_model.dart';
import '../repositories/cronograma_visita_repository.dart';

class CronogramaVisitaProvider with ChangeNotifier {
  final CronogramaVisitaRepository _repository;

  CronogramaVisitaProvider(this._repository);

  List<CronogramaVisitaModel> _cronogramas = [];
  bool _isLoading = false;
  String? _error;

  List<CronogramaVisitaModel> get cronogramas => _cronogramas;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Cargar cronogramas por cliente
  Future<void> loadCronogramasPorCliente(int clienteId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _cronogramas = await _repository.getCronogramasPorCliente(clienteId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Agregar cronograma
  Future<void> addCronograma(CronogramaVisitaModel cronograma) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.createCronograma(cronograma);
      await loadCronogramasPorCliente(cronograma.clienteId);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Actualizar cronograma
  Future<void> updateCronograma(CronogramaVisitaModel cronograma) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.updateCronogramaLocal(cronograma);
      await loadCronogramasPorCliente(cronograma.clienteId);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Eliminar cronograma
  Future<void> deleteCronograma(int id, int clienteId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.deleteCronogramaLocal(id);
      await loadCronogramasPorCliente(clienteId);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Sincronizar cronogramas
  Future<void> syncCronogramas(int clienteId) async {
    try {
      await _repository.syncCronogramas(clienteId);
      await loadCronogramasPorCliente(clienteId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Obtener días de visita como lista de strings
  List<String> getDiasDeVisita() {
    return _cronogramas
        .where((c) => c.activo)
        .map((c) => c.diaSemana)
        .toList();
  }
}
