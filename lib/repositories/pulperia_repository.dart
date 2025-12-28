import 'package:sqflite/sqflite.dart';
import '../models/pulperia_model.dart';
import '../providers/ruta_provider.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';
import '../services/database_helper.dart';

class PulperiaRepository {
  final DatabaseHelper _dbHelper;
  final ApiService _apiService;
  final ConnectivityService _connectivityService;

  PulperiaRepository(this._apiService, this._connectivityService)
      : _dbHelper = DatabaseHelper.instance;

  Future<List<PulperiaModel>> getPulperiasLocales() async {
    final db = await _dbHelper.database;
    try {
      print('Obteniendo pulperías locales...');
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT p.*, r.nombre as nombreRuta 
        FROM pulperias p 
        LEFT JOIN rutas r ON p.rutaId = r.id 
        ORDER BY p.id DESC
      ''');

      final List<Map<String, dynamic>> cambiosPendientes = await db.rawQuery(
          'SELECT * FROM cambios_pendientes WHERE tabla = ?',
          ['pulperias']
      );

      final pulperias = maps.map((map) {
        Map<String, dynamic> pulperiaMap = Map<String, dynamic>.from(map);

        final tieneCambiosPendientes = cambiosPendientes.any(
                (cambio) => cambio['id_local'] != null &&
                (cambio['id_local'] as num).toInt() == pulperiaMap['id']
        );

        if (tieneCambiosPendientes) {
          pulperiaMap['sincronizado'] = 0;
        }

        return PulperiaModel.fromMap(pulperiaMap);
      }).toList();

      print('Pulperías locales encontradas: ${pulperias.length}');
      return pulperias;
    } catch (e) {
      print('Error al obtener pulperías locales: $e');
      return [];
    }
  }

  Future<PulperiaModel> createPulperia(PulperiaModel pulperia) async {
    final db = await _dbHelper.database;
    final hasConnection = await _connectivityService.hasConnection();

    try {
      if (hasConnection) {
        try {
          final apiResponse = await _apiService.createPulperia(pulperia.toMap());
          pulperia = apiResponse.copyWith(
            sincronizado: true,
            lastSync: DateTime.now().toIso8601String(),
            verificado: true,
          );
        } catch (e) {
          print('Error al crear en servidor: $e');
          pulperia = pulperia.copyWith(
            sincronizado: false,
            servidorId: null,
          );
        }
      } else {
        print('Sin conexión - Creando pulpería localmente');
        pulperia = pulperia.copyWith(
          sincronizado: false,
          servidorId: null,
        );
      }

      final id = await db.rawInsert('''
        INSERT INTO pulperias (
          nombre, direccion, telefono, rutaId, orden, 
          cantidadClientes, sincronizado, servidorId, 
          last_sync, verificado
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''', [
        pulperia.nombre,
        pulperia.direccion,
        pulperia.telefono,
        pulperia.rutaId,
        pulperia.orden,
        pulperia.cantidadClientes,
        pulperia.sincronizado ? 1 : 0,
        pulperia.servidorId,
        pulperia.lastSync,
        pulperia.verificado ? 1 : 0,
      ]);

      pulperia = pulperia.copyWith(id: id);

      if (!pulperia.sincronizado) {
        await _registrarCambioPendiente(
          db,
          'pulperias',
          'CREATE',
          pulperia.id,
          pulperia,
        );
      }

      return pulperia;
    } catch (e) {
      print('Error en createPulperia: $e');
      rethrow;
    }
  }

  Future<PulperiaModel> updatePulperia(PulperiaModel pulperia) async {
    final db = await _dbHelper.database;
    final hasConnection = await _connectivityService.hasConnection();

    try {
      if (pulperia.id == null) {
        throw Exception('No se puede actualizar una pulpería sin ID');
      }

      final List<Map<String, dynamic>> existente = await db.rawQuery(
          'SELECT * FROM pulperias WHERE id = ?',
          [pulperia.id]
      );

      if (existente.isEmpty) {
        throw Exception('Pulpería no encontrada');
      }

      final pulperiaExistente = PulperiaModel.fromMap(existente.first);

      final pulperiaActualizada = pulperia.copyWith(
        sincronizado: false,
        servidorId: pulperiaExistente.servidorId,
        lastSync: null,
      );

      await db.rawUpdate('''
        UPDATE pulperias
        SET nombre = ?, direccion = ?, telefono = ?,
            rutaId = ?, orden = ?, cantidadClientes = ?,
            visitado = ?, fechaVisita = ?,
            sincronizado = ?, servidorId = ?, last_sync = ?,
            verificado = ?
        WHERE id = ?
      ''', [
        pulperiaActualizada.nombre,
        pulperiaActualizada.direccion,
        pulperiaActualizada.telefono,
        pulperiaActualizada.rutaId,
        pulperiaActualizada.orden,
        pulperiaActualizada.cantidadClientes,
        pulperiaActualizada.visitado ? 1 : 0,
        pulperiaActualizada.fechaVisita,
        0, // no sincronizado
        pulperiaActualizada.servidorId,
        null, // last_sync
        1, // verificado
        pulperiaActualizada.id,
      ]);

      await _registrarCambioPendiente(
        db,
        'pulperias',
        'UPDATE',
        pulperiaActualizada.id,
        pulperiaActualizada,
      );

      if (hasConnection && pulperiaExistente.servidorId != null) {
        try {
          await _apiService.updatePulperia(
            pulperiaExistente.servidorId!,
            pulperiaActualizada.toMap(),
          );

          final pulperiaSync = pulperiaActualizada.copyWith(
            sincronizado: true,
            lastSync: DateTime.now().toIso8601String(),
          );

          await db.transaction((txn) async {
            await txn.rawUpdate('''
              UPDATE pulperias 
              SET sincronizado = 1, last_sync = ?, verificado = 1
              WHERE id = ?
            ''', [pulperiaSync.lastSync, pulperiaSync.id]);

            await txn.rawDelete(
                'DELETE FROM cambios_pendientes WHERE tabla = ? AND id_local = ?',
                ['pulperias', pulperiaSync.id]
            );
          });

          return pulperiaSync;
        } catch (e) {
          print('Error al actualizar en servidor: $e');
          return pulperiaActualizada;
        }
      }

      return pulperiaActualizada;
    } catch (e) {
      print('Error en updatePulperia: $e');
      rethrow;
    }
  }

  Future<void> deletePulperia(int id) async {
    final db = await _dbHelper.database;
    final hasConnection = await _connectivityService.hasConnection();

    try {
      await db.transaction((txn) async {
        final result = await txn.rawQuery(
            'SELECT * FROM pulperias WHERE id = ?',
            [id]
        );

        if (result.isEmpty) {
          print('Pulpería no encontrada: $id');
          return;
        }

        final pulperia = PulperiaModel.fromMap(result.first);

        if (hasConnection && pulperia.servidorId != null) {
          try {
            await _apiService.deletePulperia(pulperia.servidorId!);
            print('Pulpería eliminada en servidor: ${pulperia.servidorId}');

            await txn.rawDelete('DELETE FROM pulperias WHERE id = ?', [id]);
            await txn.rawDelete(
                'DELETE FROM cambios_pendientes WHERE tabla = ? AND id_local = ?',
                ['pulperias', id]
            );
          } catch (e) {
            print('Error al eliminar en servidor: $e');
            await _registrarCambioPendiente(txn, 'pulperias', 'DELETE', id, pulperia);
            await txn.rawDelete('DELETE FROM pulperias WHERE id = ?', [id]);
          }
        } else {
          if (pulperia.servidorId != null) {
            await _registrarCambioPendiente(txn, 'pulperias', 'DELETE', id, pulperia);
          }
          await txn.rawDelete('DELETE FROM pulperias WHERE id = ?', [id]);
        }
      });

      print('Pulpería eliminada localmente: $id');
    } catch (e) {
      print('Error en deletePulperia: $e');
      rethrow;
    }
  }

  Future<void> syncPulperias(List<Map<String, dynamic>> rutasLocales) async {
    if (!await _connectivityService.hasConnection()) {
      print('No hay conexión, omitiendo sincronización');
      return;
    }

    final db = await _dbHelper.database;

    try {
      await db.transaction((txn) async {
        // 1. Procesar primero los cambios pendientes
        final cambiosPendientes = await txn.rawQuery(
            '''SELECT * FROM cambios_pendientes 
             WHERE tabla = ? ORDER BY fecha ASC''',
            ['pulperias']
        );

        print('Cambios pendientes encontrados: ${cambiosPendientes.length}');

        for (var cambio in cambiosPendientes) {
          try {
            final datos = PulperiaModel.fromJson(cambio['datos'] as String);
            final tipoOperacion = cambio['tipo_operacion'] as String;
            final idLocal = cambio['id_local'] != null ?
            (cambio['id_local'] as num).toInt() : null;
            final cambioId = (cambio['id'] as num).toInt();

            print('Procesando cambio pendiente: $tipoOperacion para ID local: $idLocal');

            switch (tipoOperacion) {
              case 'CREATE':
                if (idLocal != null) {
                  try {
                    final rutaIdLocal = rutasLocales.firstWhere(
                            (r) => r['id'] == datos.rutaId,
                        orElse: () => {}
                    );

                    if (rutaIdLocal['servidorId'] == null) {
                      print('Ruta no sincronizada para pulpería: ${datos.nombre}');
                      continue;
                    }

                    final datosActualizados = datos.copyWith(
                        rutaId: rutaIdLocal['servidorId'] as int
                    );

                    final apiResponse = await _apiService.createPulperia(datosActualizados.toMap());

                    await txn.rawUpdate(
                        '''UPDATE pulperias 
                         SET servidorId = ?, sincronizado = 1, verificado = 1,
                             last_sync = ?
                         WHERE id = ?''',
                        [
                          apiResponse.id,
                          DateTime.now().toIso8601String(),
                          idLocal
                        ]
                    );

                    await txn.rawDelete(
                        'DELETE FROM cambios_pendientes WHERE id = ?',
                        [cambioId]
                    );

                    print('Creación sincronizada exitosamente: ${datos.nombre}');
                  } catch (e) {
                    print('Error al procesar creación pendiente: $e');
                  }
                }
                break;

              case 'UPDATE':
                if (idLocal != null && datos.servidorId != null) {
                  try {
                    final rutaIdLocal = rutasLocales.firstWhere(
                            (r) => r['id'] == datos.rutaId,
                        orElse: () => {}
                    );

                    if (rutaIdLocal['servidorId'] == null) {
                      print('Ruta no sincronizada para pulpería: ${datos.nombre}');
                      continue;
                    }

                    final datosActualizados = datos.copyWith(
                        rutaId: rutaIdLocal['servidorId'] as int
                    );

                    await _apiService.updatePulperia(datos.servidorId!, datosActualizados.toMap());

                    await txn.rawUpdate(
                        '''UPDATE pulperias 
                         SET sincronizado = 1, verificado = 1, last_sync = ?
                         WHERE id = ?''',
                        [DateTime.now().toIso8601String(), idLocal]
                    );

                    await txn.rawDelete(
                        'DELETE FROM cambios_pendientes WHERE id = ?',
                        [cambioId]
                    );

                    print('Actualización sincronizada exitosamente: ${datos.nombre}');
                  } catch (e) {
                    print('Error al procesar actualización pendiente: $e');
                  }
                }
                break;

              case 'DELETE':
                if (datos.servidorId != null) {
                  try {
                    await _apiService.deletePulperia(datos.servidorId!);

                    await txn.rawDelete(
                        'DELETE FROM pulperias WHERE id = ?',
                        [idLocal]
                    );

                    await txn.rawDelete(
                        'DELETE FROM cambios_pendientes WHERE id = ?',
                        [cambioId]
                    );

                    print('Eliminación sincronizada exitosamente para ID servidor: ${datos.servidorId}');
                  } catch (e) {
                    if (e.toString().contains('404')) {
                      await txn.rawDelete(
                          'DELETE FROM cambios_pendientes WHERE id = ?',
                          [cambioId]
                      );
                      print('Pulpería ya eliminada en servidor');
                    } else {
                      print('Error al procesar eliminación pendiente: $e');
                    }
                  }
                }
                break;
            }
          } catch (e) {
            print('Error procesando cambio pendiente: $e');
            continue;
          }
        }

        // 2. Obtener datos actualizados del servidor
        final pulperiasServidor = await _apiService.getPulperias();

        Map<int, int> rutaServerToLocalId = {};
        for (var ruta in rutasLocales) {
          if (ruta['servidorId'] != null) {
            rutaServerToLocalId[ruta['servidorId'] as int] = ruta['id'] as int;
          }
        }

        await txn.rawUpdate(
            'UPDATE pulperias SET verificado = 0 WHERE sincronizado = 1'
        );

        for (var pulperia in pulperiasServidor) {
          final rutaIdLocal = rutaServerToLocalId[pulperia.rutaId];
          if (rutaIdLocal == null) {
            print('Ruta no encontrada localmente para pulpería: ${pulperia.nombre}');
            continue;
          }

          final tieneCambiosPendientes = (await txn.rawQuery(
              '''SELECT 1 FROM cambios_pendientes 
               WHERE tabla = ? AND id_local IN (
                 SELECT id FROM pulperias WHERE servidorId = ?
               ) LIMIT 1''',
              ['pulperias', pulperia.id]
          )).isNotEmpty;

          if (!tieneCambiosPendientes) {
            final existente = await txn.rawQuery(
                'SELECT * FROM pulperias WHERE servidorId = ?',
                [pulperia.id]
            );

            if (existente.isEmpty) {
              await txn.rawInsert(
                  '''INSERT INTO pulperias (
                  nombre, direccion, telefono, rutaId, orden,
                  cantidadClientes, sincronizado, servidorId,
                  last_sync, verificado
                ) VALUES (?, ?, ?, ?, ?, ?, 1, ?, ?, 1)''',
                  [
                    pulperia.nombre,
                    pulperia.direccion,
                    pulperia.telefono,
                    rutaIdLocal,
                    pulperia.orden,
                    pulperia.cantidadClientes,
                    pulperia.id,
                    DateTime.now().toIso8601String(),
                  ]
              );
            } else {
              await txn.rawUpdate(
                  '''UPDATE pulperias 
                   SET nombre = ?, direccion = ?, telefono = ?,
                       rutaId = ?, orden = ?, cantidadClientes = ?,
                       sincronizado = 1, verificado = 1,
                       last_sync = ?
                   WHERE servidorId = ?''',
                  [
                    pulperia.nombre,
                    pulperia.direccion,
                    pulperia.telefono,
                    rutaIdLocal,
                    pulperia.orden,
                    pulperia.cantidadClientes,
                    DateTime.now().toIso8601String(),
                    pulperia.id,
                  ]
              );
            }
          }
        }

        await txn.rawDelete('''
          DELETE FROM pulperias 
          WHERE verificado = 0 
            AND sincronizado = 1 
            AND id NOT IN (
              SELECT id_local FROM cambios_pendientes 
              WHERE tabla = 'pulperias'
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
  Future<void> _registrarCambioPendiente(
      DatabaseExecutor db,
      String tabla,
      String tipoOperacion,
      int? idLocal,
      PulperiaModel pulperia,
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
            pulperia.toJson(),
            DateTime.now().toIso8601String(),
          ]
      );

      print('Cambio pendiente registrado: $tipoOperacion para pulpería $idLocal');
    } catch (e) {
      print('Error al registrar cambio pendiente: $e');
      rethrow;
    }
  }

  Future<void> _procesarCreacionPendiente(
      DatabaseExecutor db,
      int cambioId,
      int? idLocal,
      PulperiaModel datos
      ) async {
    if (idLocal == null) return;

    try {
      final apiResponse = await _apiService.createPulperia(datos.toMap());

      await db.rawUpdate(
          '''UPDATE pulperias 
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
      PulperiaModel datos
      ) async {
    if (idLocal == null || datos.servidorId == null) return;

    try {
      await _apiService.updatePulperia(datos.servidorId!, datos.toMap());

      await db.rawUpdate(
          '''UPDATE pulperias 
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
      PulperiaModel datos
      ) async {
    if (datos.servidorId == null) return;

    try {
      await _apiService.deletePulperia(datos.servidorId!);

      await db.rawDelete(
          'DELETE FROM cambios_pendientes WHERE id = ?',
          [cambioId]
      );

      print('Eliminación sincronizada exitosamente para ID servidor: ${datos.servidorId}');
    } catch (e) {
      print('Error al procesar eliminación pendiente: $e');
    }
  }
}