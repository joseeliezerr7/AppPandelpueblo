import 'package:sqflite/sqflite.dart';
import '../models/ruta_model.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';
import '../services/database_helper.dart';

class RutaRepository {
  final DatabaseHelper _dbHelper;
  final ApiService _apiService;
  final ConnectivityService _connectivityService;

  RutaRepository(this._apiService, this._connectivityService)
      : _dbHelper = DatabaseHelper.instance;

  Future<List<RutaModel>> getRutasLocales() async {
    final db = await _dbHelper.database;
    try {
      print('Obteniendo rutas locales...');
      final List<Map<String, dynamic>> maps = await db.rawQuery(
          'SELECT * FROM rutas ORDER BY id DESC'
      );

      final List<Map<String, dynamic>> cambiosPendientes = await db.rawQuery(
          'SELECT * FROM cambios_pendientes WHERE tabla = ?',
          ['rutas']
      );

      final rutas = maps.map((map) {
        Map<String, dynamic> rutaMap = Map<String, dynamic>.from(map);

        final tieneCambiosPendientes = cambiosPendientes.any(
                (cambio) => cambio['id_local'] != null &&
                (cambio['id_local'] as num).toInt() == rutaMap['id']
        );

        if (tieneCambiosPendientes) {
          rutaMap['sincronizado'] = 0;
        }

        return RutaModel.fromMap(rutaMap);
      }).toList();

      print('Rutas locales encontradas: ${rutas.length}');
      return rutas;
    } catch (e) {
      print('Error al obtener rutas locales: $e');
      return [];
    }
  }

  Future<List<RutaModel>> getRutas() async {
    final hasConnection = await _connectivityService.hasConnection();
    final db = await _dbHelper.database;

    try {
      if (hasConnection) {
        print('Con conexión - Obteniendo rutas del servidor');
        final rutasServidor = await _apiService.getRutas();

        await db.transaction((txn) async {
          await txn.rawUpdate(
              'UPDATE rutas SET verificado = 0 WHERE sincronizado = 1'
          );

          for (var ruta in rutasServidor) {
            final existente = await txn.rawQuery(
                'SELECT * FROM rutas WHERE servidorId = ? LIMIT 1',
                [ruta.id]
            );

            if (existente.isEmpty) {
              await txn.rawInsert(
                  '''INSERT INTO rutas (nombre, cantidadPulperias, cantidadClientes, 
                                    servidorId, sincronizado, verificado, last_sync)
                   VALUES (?, ?, ?, ?, 1, 1, ?)''',
                  [
                    ruta.nombre,
                    ruta.cantidadPulperias,
                    ruta.cantidadClientes,
                    ruta.id,
                    DateTime.now().toIso8601String()
                  ]
              );
            } else {
              await txn.rawUpdate(
                  '''UPDATE rutas 
                   SET nombre = ?, cantidadPulperias = ?, cantidadClientes = ?,
                       sincronizado = 1, verificado = 1, last_sync = ?
                   WHERE servidorId = ?''',
                  [
                    ruta.nombre,
                    ruta.cantidadPulperias,
                    ruta.cantidadClientes,
                    DateTime.now().toIso8601String(),
                    ruta.id
                  ]
              );
            }
          }

          await txn.rawDelete(
              'DELETE FROM rutas WHERE verificado = 0 AND sincronizado = 1'
          );
        });
      }

      return getRutasLocales();
    } catch (e) {
      print('Error en getRutas: $e');
      return getRutasLocales();
    }
  }

  Future<RutaModel> createRuta(RutaModel ruta) async {
    final db = await _dbHelper.database;
    final hasConnection = await _connectivityService.hasConnection();

    try {
      if (hasConnection) {
        try {
          final apiResponse = await _apiService.createRuta(ruta.toMap());
          ruta = apiResponse.copyWith(
            sincronizado: true,
            lastSync: DateTime.now().toIso8601String(),
            verificado: true,
          );
        } catch (e) {
          print('Error al crear en servidor: $e');
          ruta = ruta.copyWith(
            sincronizado: false,
            servidorId: null,
          );
        }
      } else {
        print('Sin conexión - Creando ruta localmente');
        ruta = ruta.copyWith(
          sincronizado: false,
          servidorId: null,
        );
      }

      final id = await db.rawInsert(
          '''INSERT INTO rutas (nombre, cantidadPulperias, cantidadClientes,
                            sincronizado, servidorId, last_sync, verificado)
           VALUES (?, ?, ?, ?, ?, ?, ?)''',
          [
            ruta.nombre,
            ruta.cantidadPulperias,
            ruta.cantidadClientes,
            ruta.sincronizado ? 1 : 0,
            ruta.servidorId,
            ruta.lastSync,
            ruta.verificado ? 1 : 0,
          ]
      );

      ruta = ruta.copyWith(id: id);

      if (!ruta.sincronizado && ruta.id != null) {
        await _registrarCambioPendiente(
          db,
          'rutas',
          'CREATE',
          ruta.id,
          ruta,
        );
      }

      return ruta;
    } catch (e) {
      print('Error en createRuta: $e');
      rethrow;
    }
  }

  Future<RutaModel> updateRuta(RutaModel ruta) async {
    final db = await _dbHelper.database;
    final hasConnection = await _connectivityService.hasConnection();

    try {
      if (ruta.id == null) {
        throw Exception('No se puede actualizar una ruta sin ID');
      }

      // Obtener la ruta actual
      final List<Map<String, dynamic>> existente = await db.rawQuery(
          'SELECT * FROM rutas WHERE id = ?',
          [ruta.id]
      );

      if (existente.isEmpty) {
        throw Exception('Ruta no encontrada');
      }

      final rutaExistente = RutaModel.fromMap(existente.first);

      // Actualizar ruta local primero
      final rutaActualizada = ruta.copyWith(
        sincronizado: false,
        servidorId: rutaExistente.servidorId,
        lastSync: null,
      );

      // Actualizar en la base de datos local
      await db.rawUpdate(
          '''UPDATE rutas 
           SET nombre = ?, cantidadPulperias = ?, cantidadClientes = ?,
               sincronizado = ?, servidorId = ?, last_sync = ?, verificado = ?
           WHERE id = ?''',
          [
            rutaActualizada.nombre,
            rutaActualizada.cantidadPulperias,
            rutaActualizada.cantidadClientes,
            0,  // no sincronizado
            rutaActualizada.servidorId,
            null,  // last_sync
            1,    // verificado
            rutaActualizada.id,
          ]
      );

      if (rutaActualizada.id != null) {
        await _registrarCambioPendiente(
          db,
          'rutas',
          'UPDATE',
          rutaActualizada.id,
          rutaActualizada,
        );
      }

      // Si hay conexión, intentar sincronizar inmediatamente
      if (hasConnection && rutaExistente.servidorId != null) {
        try {
          await _apiService.updateRuta(
            rutaExistente.servidorId!,
            rutaActualizada.toMap(),
          );

          // Marcar como sincronizado
          final rutaSync = rutaActualizada.copyWith(
            sincronizado: true,
            lastSync: DateTime.now().toIso8601String(),
          );

          await db.transaction((txn) async {
            await txn.rawUpdate(
                '''UPDATE rutas 
                 SET sincronizado = 1, last_sync = ?, verificado = 1
                 WHERE id = ?''',
                [rutaSync.lastSync, rutaSync.id]
            );

            await txn.rawDelete(
                'DELETE FROM cambios_pendientes WHERE tabla = ? AND id_local = ?',
                ['rutas', rutaSync.id]
            );
          });

          return rutaSync;
        } catch (e) {
          print('Error al actualizar en servidor: $e');
          return rutaActualizada;
        }
      }

      return rutaActualizada;
    } catch (e) {
      print('Error en updateRuta: $e');
      rethrow;
    }
  }

  Future<void> deleteRuta(int id) async {
    final db = await _dbHelper.database;
    final hasConnection = await _connectivityService.hasConnection();

    try {
      await db.transaction((txn) async {
        final List<Map<String, dynamic>> result = await txn.rawQuery(
            'SELECT * FROM rutas WHERE id = ?',
            [id]
        );

        if (result.isEmpty) {
          print('Ruta no encontrada: $id');
          return;
        }

        final ruta = RutaModel.fromMap(result.first);

        // Si tiene servidorId y hay conexión, intentar eliminar en el servidor
        if (hasConnection && ruta.servidorId != null) {
          try {
            await _apiService.deleteRuta(ruta.servidorId!);
            print('Ruta eliminada en el servidor: ${ruta.servidorId}');

            // Eliminar localmente y cualquier cambio pendiente
            await txn.rawDelete('DELETE FROM rutas WHERE id = ?', [id]);
            await txn.rawDelete(
                'DELETE FROM cambios_pendientes WHERE tabla = ? AND id_local = ?',
                ['rutas', id]
            );
          } catch (e) {
            print('Error al eliminar en servidor: $e');
            // Registrar para eliminación posterior y eliminar localmente
            await _registrarCambioPendiente(txn, 'rutas', 'DELETE', id, ruta);
            await txn.rawDelete('DELETE FROM rutas WHERE id = ?', [id]);
          }
        } else {
          // Sin conexión o sin servidorId
          if (ruta.servidorId != null) {
            // Si tiene servidorId pero no hay conexión, registrar para eliminación posterior
            await _registrarCambioPendiente(txn, 'rutas', 'DELETE', id, ruta);
          }
          // Eliminar localmente en cualquier caso
          await txn.rawDelete('DELETE FROM rutas WHERE id = ?', [id]);
        }
      });

      print('Ruta eliminada localmente: $id');
    } catch (e) {
      print('Error en deleteRuta: $e');
      rethrow;
    }
  }

  Future<void> syncRutas() async {
    if (!await _connectivityService.hasConnection()) {
      print('No hay conexión, omitiendo sincronización');
      return;
    }

    final db = await _dbHelper.database;

    try {
      // 1. Procesar cambios pendientes
      await db.transaction((txn) async {
        final cambiosPendientes = await txn.rawQuery(
            '''SELECT * FROM cambios_pendientes 
             WHERE tabla = ? ORDER BY fecha ASC''',
            ['rutas']
        );

        for (var cambio in cambiosPendientes) {
          try {
            final datos = RutaModel.fromJson(cambio['datos'] as String);
            final tipoOperacion = cambio['tipo_operacion'] as String;
            final idLocal = cambio['id_local'] != null ?
            (cambio['id_local'] as num).toInt() : null;
            final cambioId = (cambio['id'] as num).toInt();

            print('Procesando cambio pendiente: $tipoOperacion para ID local: $idLocal');

            switch (tipoOperacion) {
              case 'CREATE':
                await _procesarCreacionPendiente(txn, cambioId, idLocal, datos);
                break;
              case 'UPDATE':
                await _procesarActualizacionPendiente(txn, cambioId, idLocal, datos);
                break;
              case 'DELETE':
                await _procesarEliminacionPendiente(txn, cambioId, datos);
                break;
            }
          } catch (e) {
            print('Error procesando cambio pendiente: $e');
            continue;
          }
        }
      });

      // 2. Sincronizar con servidor
      final rutasServidor = await _apiService.getRutas();

      await db.transaction((txn) async {
        // Marcar rutas existentes como no verificadas
        await txn.rawUpdate(
            'UPDATE rutas SET verificado = 0 WHERE sincronizado = 1'
        );

        // Procesar rutas del servidor
        for (var ruta in rutasServidor) {
          final tieneCambiosPendientes = (await txn.rawQuery(
              '''SELECT 1 FROM cambios_pendientes 
               WHERE tabla = ? AND id_local IN (
                 SELECT id FROM rutas WHERE servidorId = ?
               ) LIMIT 1''',
              ['rutas', ruta.id]
          )).isNotEmpty;

          if (!tieneCambiosPendientes) {
            final existente = await txn.rawQuery(
                'SELECT * FROM rutas WHERE servidorId = ?',
                [ruta.id]
            );

            if (existente.isEmpty) {
              await txn.rawInsert(
                  '''INSERT INTO rutas (nombre, cantidadPulperias, cantidadClientes,
                                    servidorId, sincronizado, verificado, last_sync)
                   VALUES (?, ?, ?, ?, 1, 1, ?)''',
                  [
                    ruta.nombre,
                    ruta.cantidadPulperias,
                    ruta.cantidadClientes,
                    ruta.id,
                    DateTime.now().toIso8601String(),
                  ]
              );
            } else {
              await txn.rawUpdate(
                  '''UPDATE rutas 
                   SET nombre = ?, cantidadPulperias = ?, cantidadClientes = ?,
                       sincronizado = 1, verificado = 1, last_sync = ?
                   WHERE servidorId = ?''',
                  [
                    ruta.nombre,
                    ruta.cantidadPulperias,
                    ruta.cantidadClientes,
                    DateTime.now().toIso8601String(),
                    ruta.id
                  ]
              );
            }
          }
        }

        // Eliminar rutas obsoletas
        await txn.rawDelete('''
          DELETE FROM rutas 
          WHERE verificado = 0 
            AND sincronizado = 1 
            AND id NOT IN (
              SELECT id_local FROM cambios_pendientes 
              WHERE tabla = 'rutas'
            )
        ''');
      });

      print('Sincronización completada exitosamente');
    } catch (e) {
      print('Error en sincronización: $e');
      rethrow;
    }
  }

  // Métodos auxiliares para procesar cambios pendientes
  Future<void> _procesarCreacionPendiente(
      DatabaseExecutor db,
      int cambioId,
      int? idLocal,
      RutaModel datos
      ) async {
    if (idLocal == null) return;

    try {
      final apiResponse = await _apiService.createRuta(datos.toMap());

      await db.rawUpdate(
          '''UPDATE rutas 
           SET servidorId = ?, sincronizado = 1, verificado = 1,
               last_sync = ?
           WHERE id = ?''',
          [
            apiResponse.id,
            DateTime.now().toIso8601String(),
            idLocal
          ]
      );

      await db.rawDelete(
          'DELETE FROM cambios_pendientes WHERE id = ?',
          [cambioId]
      );

      print('Creación sincronizada exitosamente para ID local: $idLocal');
    } catch (e) {
      print('Error al procesar creación pendiente: $e');
    }
  }

  Future<void> _procesarActualizacionPendiente(
      DatabaseExecutor db,
      int cambioId,
      int? idLocal,
      RutaModel datos
      ) async {
    if (idLocal == null || datos.servidorId == null) return;

    try {
      await _apiService.updateRuta(datos.servidorId!, datos.toMap());

      await db.rawUpdate(
          '''UPDATE rutas 
           SET sincronizado = 1, verificado = 1, last_sync = ?
           WHERE id = ?''',
          [DateTime.now().toIso8601String(), idLocal]
      );

      await db.rawDelete(
          'DELETE FROM cambios_pendientes WHERE id = ?',
          [cambioId]
      );

      print('Actualización sincronizada exitosamente para ID local: $idLocal');
    } catch (e) {
      print('Error al procesar actualización pendiente: $e');
    }
  }

  Future<void> _procesarEliminacionPendiente(
      DatabaseExecutor db,
      int cambioId,
      RutaModel datos
      ) async {
    if (datos.servidorId == null) return;

    try {
      await _apiService.deleteRuta(datos.servidorId!);

      await db.rawDelete(
          'DELETE FROM cambios_pendientes WHERE id = ?',
          [cambioId]
      );

      print('Eliminación sincronizada exitosamente para ID servidor: ${datos.servidorId}');
    } catch (e) {
      print('Error al procesar eliminación pendiente: $e');
    }
  }

  Future<void> _registrarCambioPendiente(
      DatabaseExecutor db,
      String tabla,
      String tipoOperacion,
      int? idLocal,  // Cambiar a int?
      RutaModel ruta,
      ) async {
    if (idLocal == null) {
      print('No se puede registrar cambio pendiente sin ID local');
      return;
    }

    try {
      await db.rawDelete(
          '''DELETE FROM cambios_pendientes 
         WHERE tabla = ? AND id_local = ?''',
          [tabla, idLocal]
      );

      await db.rawInsert(
          '''INSERT INTO cambios_pendientes 
         (tabla, tipo_operacion, id_local, datos, fecha)
         VALUES (?, ?, ?, ?, ?)''',
          [
            tabla,
            tipoOperacion,
            idLocal,
            ruta.toJson(),
            DateTime.now().toIso8601String(),
          ]
      );

      print('Cambio pendiente registrado: $tipoOperacion para ruta $idLocal');
    } catch (e) {
      print('Error al registrar cambio pendiente: $e');
      rethrow;
    }
  }
  }
