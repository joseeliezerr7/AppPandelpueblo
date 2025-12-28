import 'package:sqflite/sqflite.dart';
import '../models/visita_cliente_model.dart';
import '../services/database_helper.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';

class VisitaClienteRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ApiService _apiService;
  final ConnectivityService _connectivityService;

  VisitaClienteRepository(this._apiService, this._connectivityService);

  // Obtener visitas locales por cliente
  Future<List<VisitaClienteModel>> getVisitasPorCliente(int clienteId) async {
    final hasConnection = await _connectivityService.hasConnection();

    try {
      if (hasConnection) {
        // Si hay conexión, obtener del servidor
        print('✓ Hay conexión - Obteniendo visitas desde servidor para cliente $clienteId');
        final visitas = await _apiService.getVisitasPorCliente(clienteId);
        return visitas;
      } else {
        // Sin conexión, obtener de la BD local
        print('✗ Sin conexión - Obteniendo visitas desde BD local');
        final db = await _dbHelper.database;
        final List<Map<String, dynamic>> maps = await db.query(
          'visitas_clientes',
          where: 'clienteId = ?',
          whereArgs: [clienteId],
          orderBy: 'fecha DESC',
        );
        return List.generate(maps.length, (i) => VisitaClienteModel.fromMap(maps[i]));
      }
    } catch (e) {
      print('Error al obtener visitas: $e');
      rethrow;
    }
  }

  // Obtener todas las visitas locales
  Future<List<VisitaClienteModel>> getVisitasLocales() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'visitas_clientes',
        orderBy: 'fecha DESC',
      );
      return List.generate(maps.length, (i) => VisitaClienteModel.fromMap(maps[i]));
    } catch (e) {
      print('Error al obtener visitas locales: $e');
      rethrow;
    }
  }

  // Crear visita (verifica conectividad)
  Future<VisitaClienteModel> createVisita(VisitaClienteModel visita) async {
    final hasConnection = await _connectivityService.hasConnection();

    try {
      if (hasConnection) {
        print('✓ Hay conexión - Creando visita en servidor');
        try {
          final visitaData = {
            'clienteId': visita.clienteId,
            'fecha': visita.fecha,
            'realizada': visita.realizada,
            'notas': visita.notas,
          };

          final response = await _apiService.createVisitaCliente(visitaData);

          final visitaServidor = VisitaClienteModel(
            id: null,
            servidorId: response['id'],
            clienteId: visita.clienteId,
            fecha: visita.fecha,
            realizada: visita.realizada,
            notas: visita.notas,
            sincronizado: true,
          );

          final visitaId = await _insertVisitaLocalSinPendiente(visitaServidor);
          return visitaServidor.copyWith(id: visitaId);
        } catch (e) {
          print('✗ Error al crear en servidor: $e');
          print('→ Guardando localmente para sincronizar después');
          final visitaId = await _insertVisitaLocal(visita);
          return visita.copyWith(id: visitaId);
        }
      } else {
        print('✗ Sin conexión - Creando visita localmente');
        final visitaId = await _insertVisitaLocal(visita);
        return visita.copyWith(id: visitaId);
      }
    } catch (e) {
      print('Error en createVisita: $e');
      rethrow;
    }
  }

  // Insertar visita local con cambios pendientes
  Future<int> _insertVisitaLocal(VisitaClienteModel visita) async {
    try {
      final db = await _dbHelper.database;
      final id = await db.insert(
        'visitas_clientes',
        visita.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Registrar cambio pendiente
      await _registrarCambioPendiente(db, 'INSERT', id, visita.toMap());
      return id;
    } catch (e) {
      print('Error al insertar visita local: $e');
      rethrow;
    }
  }

  // Insertar visita local SIN cambios pendientes (ya sincronizado)
  Future<int> _insertVisitaLocalSinPendiente(VisitaClienteModel visita) async {
    try {
      final db = await _dbHelper.database;
      final id = await db.insert(
        'visitas_clientes',
        visita.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return id;
    } catch (e) {
      print('Error al insertar visita sincronizada: $e');
      rethrow;
    }
  }

  // Actualizar visita local
  Future<int> updateVisitaLocal(VisitaClienteModel visita) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.update(
        'visitas_clientes',
        visita.copyWith(sincronizado: false).toMap(),
        where: 'id = ?',
        whereArgs: [visita.id],
      );

      await _registrarCambioPendiente(db, 'UPDATE', visita.id!, visita.toMap());
      return result;
    } catch (e) {
      print('Error al actualizar visita local: $e');
      rethrow;
    }
  }

  // Eliminar visita local
  Future<int> deleteVisitaLocal(int id) async {
    try {
      final db = await _dbHelper.database;

      await _registrarCambioPendiente(db, 'DELETE', id, {});

      return await db.delete(
        'visitas_clientes',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error al eliminar visita local: $e');
      rethrow;
    }
  }

  // Sincronizar visitas con servidor
  Future<void> syncVisitas(int clienteId) async {
    try {
      print('=== Sincronizando visitas del cliente $clienteId ===');

      // Obtener visitas del servidor
      final visitasServidor = await _apiService.getVisitasClientes(clienteId: clienteId);
      final db = await _dbHelper.database;

      for (var visitaData in visitasServidor) {
        final visita = VisitaClienteModel.fromJson(visitaData);

        // Buscar si existe localmente por servidorId
        final List<Map<String, dynamic>> existing = await db.query(
          'visitas_clientes',
          where: 'servidorId = ?',
          whereArgs: [visita.servidorId],
        );

        if (existing.isEmpty) {
          // Insertar nueva visita desde servidor
          await db.insert(
            'visitas_clientes',
            visita.copyWith(sincronizado: true).toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } else {
          // Actualizar visita existente
          final idLocal = existing.first['id'] as int;
          await db.update(
            'visitas_clientes',
            visita.copyWith(id: idLocal, sincronizado: true).toMap(),
            where: 'id = ?',
            whereArgs: [idLocal],
          );
        }
      }

      print('✓ Visitas sincronizadas');
    } catch (e) {
      print('Error en sincronización de visitas: $e');
      rethrow;
    }
  }

  // Marcar visita como realizada
  Future<void> marcarComoRealizada(int visitaId, {String? notas}) async {
    try {
      final db = await _dbHelper.database;
      await db.update(
        'visitas_clientes',
        {
          'realizada': 1,
          'notas': notas,
          'sincronizado': 0,
        },
        where: 'id = ?',
        whereArgs: [visitaId],
      );

      await _registrarCambioPendiente(db, 'UPDATE', visitaId, {
        'realizada': true,
        'notas': notas,
      });
    } catch (e) {
      print('Error al marcar visita como realizada: $e');
      rethrow;
    }
  }

  // Registrar cambio pendiente
  Future<void> _registrarCambioPendiente(
    Database db,
    String operacion,
    int idLocal,
    Map<String, dynamic> datos,
  ) async {
    try {
      await db.insert('cambios_pendientes', {
        'tabla': 'visitas_clientes',
        'tipo_operacion': operacion,
        'id_local': idLocal,
        'datos': datos.toString(),
        'fecha': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error al registrar cambio pendiente: $e');
    }
  }
}
