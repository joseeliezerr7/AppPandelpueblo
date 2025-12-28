import 'package:flutter/foundation.dart';
import '../models/visita_cliente_model.dart';
import '../repositories/visita_cliente_repository.dart';

class VisitaClienteProvider with ChangeNotifier {
  final VisitaClienteRepository _repository;

  VisitaClienteProvider(this._repository);

  List<VisitaClienteModel> _visitas = [];
  bool _isLoading = false;
  String? _error;

  List<VisitaClienteModel> get visitas => _visitas;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Cargar visitas por cliente
  Future<void> loadVisitasPorCliente(int clienteId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _visitas = await _repository.getVisitasPorCliente(clienteId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cargar todas las visitas locales
  Future<void> loadVisitasLocales() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _visitas = await _repository.getVisitasLocales();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Agregar visita
  Future<void> addVisita(VisitaClienteModel visita) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.createVisita(visita);
      await loadVisitasPorCliente(visita.clienteId);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Actualizar visita
  Future<void> updateVisita(VisitaClienteModel visita) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.updateVisitaLocal(visita);
      await loadVisitasPorCliente(visita.clienteId);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Eliminar visita
  Future<void> deleteVisita(int id, int clienteId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.deleteVisitaLocal(id);
      await loadVisitasPorCliente(clienteId);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Marcar visita como realizada
  Future<void> marcarComoRealizada(int visitaId, int clienteId, {String? notas}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.marcarComoRealizada(visitaId, notas: notas);
      await loadVisitasPorCliente(clienteId);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Sincronizar visitas
  Future<void> syncVisitas(int clienteId) async {
    try {
      await _repository.syncVisitas(clienteId);
      await loadVisitasPorCliente(clienteId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Obtener visitas pendientes (no realizadas)
  List<VisitaClienteModel> getVisitasPendientes() {
    return _visitas.where((v) => !v.realizada).toList();
  }

  // Obtener visitas realizadas
  List<VisitaClienteModel> getVisitasRealizadas() {
    return _visitas.where((v) => v.realizada).toList();
  }

  // Obtener visitas por rango de fechas
  List<VisitaClienteModel> getVisitasPorFechas(DateTime desde, DateTime hasta) {
    return _visitas.where((v) {
      final fecha = DateTime.parse(v.fecha);
      return fecha.isAfter(desde.subtract(const Duration(days: 1))) &&
             fecha.isBefore(hasta.add(const Duration(days: 1)));
    }).toList();
  }
}
