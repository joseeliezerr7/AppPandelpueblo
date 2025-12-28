import 'package:sqflite/sqflite.dart';
import '../models/cronograma_visita_model.dart';
import '../services/database_helper.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';

class CronogramaVisitaRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ApiService _apiService;
  final ConnectivityService _connectivityService;

  CronogramaVisitaRepository(this._apiService, this._connectivityService);

  // Obtener cronogramas locales por cliente
  Future<List<CronogramaVisitaModel>> getCronogramasPorCliente(int clienteId) async {
    final hasConnection = await _connectivityService.hasConnection();

    try {
      if (hasConnection) {
        // Si hay conexión, obtener del servidor
        print('✓ Hay conexión - Obteniendo cronogramas desde servidor para cliente $clienteId');
        final cronogramas = await _apiService.getCronogramasPorCliente(clienteId);
        return cronogramas;
      } else {
        // Sin conexión, obtener de la BD local
        print('✗ Sin conexión - Obteniendo cronogramas desde BD local');
        final db = await _dbHelper.database;
        final List<Map<String, dynamic>> maps = await db.query(
          'cronograma_visitas',
          where: 'clienteId = ?',
          whereArgs: [clienteId],
          orderBy: 'orden ASC',
        );
        return List.generate(maps.length, (i) => CronogramaVisitaModel.fromMap(maps[i]));
      }
    } catch (e) {
      print('Error al obtener cronogramas: $e');
      rethrow;
    }
  }

  // Crear cronograma (verifica conectividad)
  Future<CronogramaVisitaModel> createCronograma(CronogramaVisitaModel cronograma) async {
    final hasConnection = await _connectivityService.hasConnection();

    try {
      if (hasConnection) {
        print('✓ Hay conexión - Creando cronograma en servidor');
        try {
          final cronogramaData = {
            'clienteId': cronograma.clienteId,
            'dia_semana': cronograma.diaSemana,
            'orden': cronograma.orden,
            'activo': cronograma.activo,
          };

          final response = await _apiService.createCronogramaVisita(cronogramaData);

          final cronogramaServidor = CronogramaVisitaModel(
            id: null,
            servidorId: response['id'],
            clienteId: cronograma.clienteId,
            diaSemana: cronograma.diaSemana,
            orden: cronograma.orden,
            activo: cronograma.activo,
            sincronizado: true,
          );

          final cronogramaId = await _insertCronogramaLocalSinPendiente(cronogramaServidor);
          return cronogramaServidor.copyWith(id: cronogramaId);
        } catch (e) {
          print('✗ Error al crear en servidor: $e');
          print('→ Guardando localmente para sincronizar después');
          final cronogramaId = await _insertCronogramaLocal(cronograma);
          return cronograma.copyWith(id: cronogramaId);
        }
      } else {
        print('✗ Sin conexión - Creando cronograma localmente');
        final cronogramaId = await _insertCronogramaLocal(cronograma);
        return cronograma.copyWith(id: cronogramaId);
      }
    } catch (e) {
      print('Error en createCronograma: $e');
      rethrow;
    }
  }

  // Insertar cronograma local con cambios pendientes
  Future<int> _insertCronogramaLocal(CronogramaVisitaModel cronograma) async {
    try {
      final db = await _dbHelper.database;
      final id = await db.insert(
        'cronograma_visitas',
        cronograma.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Registrar cambio pendiente
      await _registrarCambioPendiente(db, 'INSERT', id, cronograma.toMap());
      return id;
    } catch (e) {
      print('Error al insertar cronograma local: $e');
      rethrow;
    }
  }

  // Insertar cronograma local SIN cambios pendientes (ya sincronizado)
  Future<int> _insertCronogramaLocalSinPendiente(CronogramaVisitaModel cronograma) async {
    try {
      final db = await _dbHelper.database;
      final id = await db.insert(
        'cronograma_visitas',
        cronograma.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return id;
    } catch (e) {
      print('Error al insertar cronograma sincronizado: $e');
      rethrow;
    }
  }

  // Actualizar cronograma local
  Future<int> updateCronogramaLocal(CronogramaVisitaModel cronograma) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.update(
        'cronograma_visitas',
        cronograma.copyWith(sincronizado: false).toMap(),
        where: 'id = ?',
        whereArgs: [cronograma.id],
      );

      await _registrarCambioPendiente(db, 'UPDATE', cronograma.id!, cronograma.toMap());
      return result;
    } catch (e) {
      print('Error al actualizar cronograma local: $e');
      rethrow;
    }
  }

  // Eliminar cronograma local
  Future<int> deleteCronogramaLocal(int id) async {
    try {
      final db = await _dbHelper.database;

      await _registrarCambioPendiente(db, 'DELETE', id, {});

      return await db.delete(
        'cronograma_visitas',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error al eliminar cronograma local: $e');
      rethrow;
    }
  }

  // Sincronizar cronogramas con servidor
  Future<void> syncCronogramas(int clienteId) async {
    try {
      print('=== Sincronizando cronogramas del cliente $clienteId ===');

      // Obtener cronogramas del servidor
      final cronogramasServidor = await _apiService.getCronogramaVisitas(clienteId: clienteId);
      final db = await _dbHelper.database;

      for (var cronogramaData in cronogramasServidor) {
        final cronograma = CronogramaVisitaModel.fromJson(cronogramaData);

        // Buscar si existe localmente por servidorId
        final List<Map<String, dynamic>> existing = await db.query(
          'cronograma_visitas',
          where: 'servidorId = ?',
          whereArgs: [cronograma.servidorId],
        );

        if (existing.isEmpty) {
          // Insertar nuevo cronograma desde servidor
          await db.insert(
            'cronograma_visitas',
            cronograma.copyWith(sincronizado: true).toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } else {
          // Actualizar cronograma existente
          final idLocal = existing.first['id'] as int;
          await db.update(
            'cronograma_visitas',
            cronograma.copyWith(id: idLocal, sincronizado: true).toMap(),
            where: 'id = ?',
            whereArgs: [idLocal],
          );
        }
      }

      print('✓ Cronogramas sincronizados');
    } catch (e) {
      print('Error en sincronización de cronogramas: $e');
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
        'tabla': 'cronograma_visitas',
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
