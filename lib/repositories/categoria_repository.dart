import 'package:sqflite/sqflite.dart';
import '../models/categoria_model.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';
import '../services/database_helper.dart';
import 'dart:convert';

class CategoriaRepository {
  final DatabaseHelper _dbHelper;
  final ApiService _apiService;
  final ConnectivityService _connectivityService;

  CategoriaRepository(this._apiService, this._connectivityService)
      : _dbHelper = DatabaseHelper.instance;

  Future<List<CategoriaModel>> getCategoriasLocales() async {
    final db = await _dbHelper.database;
    try {
      print('Obteniendo categorías locales...');
      final List<Map<String, dynamic>> maps = await db.rawQuery(
          'SELECT * FROM categorias ORDER BY id DESC'
      );

      // Verificar cambios pendientes para cada categoría
      final List<Map<String, dynamic>> cambiosPendientes = await db.rawQuery(
          'SELECT * FROM cambios_pendientes WHERE tabla = ?',
          ['categorias']
      );

      final categorias = maps.map((map) {
        Map<String, dynamic> categoriaMap = Map<String, dynamic>.from(map);

        final tieneCambiosPendientes = cambiosPendientes.any(
                (cambio) => cambio['id_local'] != null &&
                (cambio['id_local'] as num).toInt() == categoriaMap['id']
        );

        if (tieneCambiosPendientes) {
          categoriaMap['sincronizado'] = 0;
        }

        return CategoriaModel.fromMap(categoriaMap);
      }).toList();

      print('Categorías locales encontradas: ${categorias.length}');
      return categorias;
    } catch (e) {
      print('Error al obtener categorías locales: $e');
      return [];
    }
  }

  Future<List<CategoriaModel>> getCategorias() async {
    final hasConnection = await _connectivityService.hasConnection();
    final db = await _dbHelper.database;

    try {
      // Primero obtener categorías locales no sincronizadas
      final List<Map<String, dynamic>> localMaps = await db.rawQuery(
          'SELECT * FROM categorias WHERE sincronizado = ?',
          [0]
      );

      final List<CategoriaModel> categoriasNoSincronizadas =
      localMaps.map((map) => CategoriaModel.fromMap(map)).toList();

      if (hasConnection) {
        print('Con conexión - Obteniendo categorías del servidor');
        final categoriasServidor = await _apiService.getCategorias();

        await db.transaction((txn) async {
          // Marcar todas las categorías sincronizadas como no verificadas
          await txn.rawUpdate(
              'UPDATE categorias SET verificado = 0 WHERE sincronizado = 1'
          );

          // Actualizar o insertar categorías del servidor
          for (var categoria in categoriasServidor) {
            final existente = await txn.rawQuery(
                'SELECT * FROM categorias WHERE servidorId = ? LIMIT 1',
                [categoria.id]
            );

            if (existente.isEmpty) {
              await txn.rawInsert(
                  '''INSERT INTO categorias 
                   (nombre, servidorId, sincronizado, verificado, last_sync)
                   VALUES (?, ?, 1, 1, ?)''',
                  [categoria.nombre, categoria.id, DateTime.now().toIso8601String()]
              );
            } else {
              await txn.rawUpdate(
                  '''UPDATE categorias 
                   SET nombre = ?, sincronizado = 1, verificado = 1, 
                       last_sync = ?
                   WHERE servidorId = ?''',
                  [
                    categoria.nombre,
                    DateTime.now().toIso8601String(),
                    categoria.id
                  ]
              );
            }
          }

          // Eliminar categorías no verificadas que estaban sincronizadas
          await txn.rawDelete(
              'DELETE FROM categorias WHERE verificado = 0 AND sincronizado = 1'
          );
        });
      }

      // Obtener todas las categorías después de la actualización
      final List<Map<String, dynamic>> allMaps = await db.rawQuery(
          'SELECT * FROM categorias'
      );
      print('Total categorías en BD local: ${allMaps.length}');
      return allMaps.map((map) => CategoriaModel.fromMap(map)).toList();
    } catch (e) {
      print('Error en getCategorias: $e');
      return getCategoriasLocales();
    }
  }

  Future<CategoriaModel> createCategoria(CategoriaModel categoria) async {
    final db = await _dbHelper.database;
    final hasConnection = await _connectivityService.hasConnection();

    try {
      if (hasConnection) {
        try {
          final apiResponse = await _apiService.createCategoria(categoria.toMap());
          categoria = apiResponse.copyWith(
            sincronizado: true,
            lastSync: DateTime.now().toIso8601String(),
            verificado: true,
          );
        } catch (e) {
          print('Error al crear en servidor: $e');
          categoria = categoria.copyWith(
            sincronizado: false,
            servidorId: null,
          );
        }
      } else {
        print('Sin conexión - Creando categoría localmente');
        categoria = categoria.copyWith(
          sincronizado: false,
          servidorId: null,
        );
      }

      // Insertar en base de datos local usando rawInsert
      final id = await db.rawInsert(
          '''INSERT INTO categorias (nombre, sincronizado, servidorId, last_sync, verificado)
           VALUES (?, ?, ?, ?, ?)''',
          [
            categoria.nombre,
            categoria.sincronizado ? 1 : 0,
            categoria.servidorId,
            categoria.lastSync,
            categoria.verificado ? 1 : 0,
          ]
      );

      categoria = categoria.copyWith(id: id);

      // Si no está sincronizado, registrar cambio pendiente
      if (!categoria.sincronizado && categoria.id != null) {
        await _registrarCambioPendiente(
          db,
          'categorias',
          'CREATE',
          categoria.id,
          categoria,
        );
      }

      return categoria;
    } catch (e) {
      print('Error en createCategoria: $e');
      rethrow;
    }
  }
  Future<CategoriaModel> updateCategoria(CategoriaModel categoria) async {
    final db = await _dbHelper.database;
    final hasConnection = await _connectivityService.hasConnection();

    try {
      if (categoria.id == null) {
        throw Exception('No se puede actualizar una categoría sin ID');
      }

      // Obtener la categoría actual
      final List<Map<String, dynamic>> existente = await db.rawQuery(
          'SELECT * FROM categorias WHERE id = ?',
          [categoria.id]
      );

      if (existente.isEmpty) {
        throw Exception('Categoría no encontrada');
      }

      final categoriaExistente = CategoriaModel.fromMap(existente.first);

      // Actualizar categoría local primero
      final categoriaActualizada = categoria.copyWith(
        sincronizado: false,
        servidorId: categoriaExistente.servidorId,
        lastSync: null,
      );

      // Actualizar en la base de datos local
      await db.rawUpdate(
          '''UPDATE categorias 
           SET nombre = ?, sincronizado = ?, servidorId = ?, 
               last_sync = ?, verificado = ?
           WHERE id = ?''',
          [
            categoriaActualizada.nombre,
            0,  // no sincronizado
            categoriaActualizada.servidorId,
            null,  // last_sync
            1,    // verificado
            categoriaActualizada.id,
          ]
      );

      // Registrar cambio pendiente
      await _registrarCambioPendiente(
        db,
        'categorias',
        'UPDATE',
        categoriaActualizada.id,
        categoriaActualizada,
      );

      // Si hay conexión, intentar sincronizar inmediatamente
      if (hasConnection && categoriaExistente.servidorId != null) {
        try {
          await _apiService.updateCategoria(
            categoriaExistente.servidorId!,
            categoriaActualizada.toMap(),
          );

          // Marcar como sincronizado en la base de datos local
          final categoriaSync = categoriaActualizada.copyWith(
            sincronizado: true,
            lastSync: DateTime.now().toIso8601String(),
          );

          await db.transaction((txn) async {
            await txn.rawUpdate(
                '''UPDATE categorias 
                 SET nombre = ?, sincronizado = 1, last_sync = ?, verificado = 1
                 WHERE id = ?''',
                [
                  categoriaSync.nombre,
                  categoriaSync.lastSync,
                  categoriaSync.id,
                ]
            );

            // Eliminar el cambio pendiente
            await txn.rawDelete(
                'DELETE FROM cambios_pendientes WHERE tabla = ? AND id_local = ?',
                ['categorias', categoriaSync.id]
            );
          });

          return categoriaSync;
        } catch (e) {
          print('Error al actualizar en servidor: $e');
          return categoriaActualizada;
        }
      }

      return categoriaActualizada;
    } catch (e) {
      print('Error en updateCategoria: $e');
      rethrow;
    }
  }

  Future<void> _procesarActualizacionPendiente(
      Database db,
      int cambioId,
      int? idLocal,
      CategoriaModel datos
      ) async {
    if (idLocal == null || datos.servidorId == null) return;

    try {
      // Intentar actualizar en el servidor
      await _apiService.updateCategoria(datos.servidorId!, datos.toMap());

      // Actualizar estado local
      await db.transaction((txn) async {
        // Marcar como sincronizado
        await txn.rawUpdate(
            '''UPDATE categorias 
             SET nombre = ?, sincronizado = 1, verificado = 1,
                 last_sync = ?
             WHERE id = ?''',
            [
              datos.nombre,
              DateTime.now().toIso8601String(),
              idLocal
            ]
        );

        // Eliminar el cambio pendiente
        await txn.rawDelete(
            'DELETE FROM cambios_pendientes WHERE id = ?',
            [cambioId]
        );
      });

      print('Actualización sincronizada exitosamente: ${datos.nombre}');
    } catch (e) {
      print('Error al procesar actualización pendiente: $e');
      throw Exception('Error al actualizar categoría: $e');
    }
  }

  Future<void> deleteCategoria(int id) async {
    final db = await _dbHelper.database;
    final hasConnection = await _connectivityService.hasConnection();

    try {
      await db.transaction((txn) async {
        // Obtener la categoría antes de eliminarla
        final List<Map<String, dynamic>> result = await txn.rawQuery(
            'SELECT * FROM categorias WHERE id = ?',
            [id]
        );

        if (result.isEmpty) {
          print('Categoría no encontrada: $id');
          return;
        }

        final categoria = CategoriaModel.fromMap(result.first);

        // Si tiene servidorId y hay conexión, intentar eliminar en el servidor
        if (hasConnection && categoria.servidorId != null) {
          try {
            await _apiService.deleteCategoria(categoria.servidorId!);
            print('Categoría eliminada en el servidor: ${categoria.servidorId}');

            // Eliminar localmente y cualquier cambio pendiente
            await txn.rawDelete('DELETE FROM categorias WHERE id = ?', [id]);
            await txn.rawDelete(
                'DELETE FROM cambios_pendientes WHERE tabla = ? AND id_local = ?',
                ['categorias', id]
            );
          } catch (e) {
            print('Error al eliminar en servidor: $e');
            // Registrar para eliminación posterior y eliminar localmente
            await _registrarEliminacionPendiente(txn, id, categoria);
            await txn.rawDelete('DELETE FROM categorias WHERE id = ?', [id]);
          }
        } else {
          // Sin conexión o sin servidorId
          if (categoria.servidorId != null) {
            // Si tiene servidorId pero no hay conexión, registrar para eliminación posterior
            await _registrarEliminacionPendiente(txn, id, categoria);
          }
          // Eliminar localmente en cualquier caso
          await txn.rawDelete('DELETE FROM categorias WHERE id = ?', [id]);
        }
      });

      print('Categoría eliminada localmente: $id');
    } catch (e) {
      print('Error en deleteCategoria: $e');
      rethrow;
    }
  }
  Future<void> _registrarEliminacionPendiente(
      DatabaseExecutor db,
      int idLocal,
      CategoriaModel categoria,
      ) async {
    try {
      // Eliminar cualquier cambio pendiente existente
      await db.rawDelete(
          'DELETE FROM cambios_pendientes WHERE tabla = ? AND id_local = ?',
          ['categorias', idLocal]
      );

      // Registrar la eliminación pendiente
      await db.rawInsert(
          '''INSERT INTO cambios_pendientes 
         (tabla, tipo_operacion, id_local, datos, fecha)
         VALUES (?, ?, ?, ?, ?)''',
          [
            'categorias',
            'DELETE',
            idLocal,
            categoria.toJson(),
            DateTime.now().toIso8601String(),
          ]
      );

      print('Eliminación pendiente registrada para categoría $idLocal');
    } catch (e) {
      print('Error al registrar eliminación pendiente: $e');
      rethrow;
    }
  }

  Future<void> syncCategorias() async {
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
            ['categorias']
        );

        for (var cambio in cambiosPendientes) {
          try {
            final datos = CategoriaModel.fromJson(cambio['datos'] as String);
            final tipoOperacion = cambio['tipo_operacion'] as String;
            final idLocal = cambio['id_local'] != null ?
            (cambio['id_local'] as num).toInt() : null;
            final cambioId = (cambio['id'] as num).toInt();

            print('Procesando cambio pendiente: $tipoOperacion para ID local: $idLocal');

            switch (tipoOperacion) {
              case 'CREATE':
                if (idLocal != null) {
                  try {
                    final apiResponse = await _apiService.createCategoria(datos.toMap());
                    await txn.rawUpdate(
                        '''UPDATE categorias 
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
                    print('Creación sincronizada exitosamente para ID local: $idLocal');
                  } catch (e) {
                    print('Error al sincronizar creación: $e');
                    continue;
                  }
                }
                break;

              case 'UPDATE':
                if (idLocal != null && datos.servidorId != null) {
                  try {
                    await _apiService.updateCategoria(
                        datos.servidorId!,
                        datos.toMap()
                    );
                    await txn.rawUpdate(
                        '''UPDATE categorias 
                       SET sincronizado = 1, verificado = 1,
                           last_sync = ?
                       WHERE id = ?''',
                        [
                          DateTime.now().toIso8601String(),
                          idLocal
                        ]
                    );
                    await txn.rawDelete(
                        'DELETE FROM cambios_pendientes WHERE id = ?',
                        [cambioId]
                    );
                    print('Actualización sincronizada exitosamente para ID local: $idLocal');
                  } catch (e) {
                    if (e.toString().contains('404')) {
                      print('Categoría no encontrada en servidor, limpiando cambio pendiente');
                      await txn.rawDelete(
                          'DELETE FROM cambios_pendientes WHERE id = ?',
                          [cambioId]
                      );
                    } else {
                      print('Error al sincronizar actualización: $e');
                    }
                    continue;
                  }
                }
                break;

              case 'DELETE':
                if (datos.servidorId != null) {
                  try {
                    await _apiService.deleteCategoria(datos.servidorId!);

                    // Limpieza después de eliminación exitosa
                    await txn.rawDelete(
                        'DELETE FROM cambios_pendientes WHERE id = ?',
                        [cambioId]
                    );
                    await txn.rawDelete(
                        'DELETE FROM categorias WHERE id = ? OR servidorId = ?',
                        [idLocal, datos.servidorId]
                    );
                    print('Eliminación sincronizada exitosamente para ID servidor: ${datos.servidorId}');
                  } catch (e) {
                    if (e.toString().contains('404') || e.toString().contains('400')) {
                      print('Categoría ya no existe en servidor, limpiando localmente');
                      await txn.rawDelete(
                          'DELETE FROM cambios_pendientes WHERE id = ?',
                          [cambioId]
                      );
                      await txn.rawDelete(
                          'DELETE FROM categorias WHERE id = ?',
                          [idLocal]
                      );
                    } else {
                      print('Error al sincronizar eliminación: $e');
                      continue;
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

        // 2. Sincronizar con el servidor
        try {
          print('Obteniendo categorías del servidor...');
          final categoriasServidor = await _apiService.getCategorias();

          // Marcar categorías existentes como no verificadas
          await txn.rawUpdate(
              'UPDATE categorias SET verificado = 0 WHERE sincronizado = 1'
          );

          // Procesar categorías del servidor
          for (var categoria in categoriasServidor) {
            // Verificar si hay cambios pendientes para esta categoría
            final tieneCambiosPendientes = (await txn.rawQuery(
                '''SELECT 1 FROM cambios_pendientes 
               WHERE tabla = ? AND id_local IN (
                 SELECT id FROM categorias WHERE servidorId = ?
               ) LIMIT 1''',
                ['categorias', categoria.id]
            )).isNotEmpty;

            if (!tieneCambiosPendientes) {
              final existente = await txn.rawQuery(
                  'SELECT * FROM categorias WHERE servidorId = ?',
                  [categoria.id]
              );

              if (existente.isEmpty) {
                // Nueva categoría del servidor
                await txn.rawInsert(
                    '''INSERT INTO categorias 
                   (nombre, servidorId, sincronizado, verificado, last_sync)
                   VALUES (?, ?, 1, 1, ?)''',
                    [
                      categoria.nombre,
                      categoria.id,
                      DateTime.now().toIso8601String(),
                    ]
                );
                print('Nueva categoría del servidor insertada: ${categoria.nombre}');
              } else {
                // Actualizar categoría existente
                await txn.rawUpdate(
                    '''UPDATE categorias 
                   SET nombre = ?, sincronizado = 1, verificado = 1,
                       last_sync = ?
                   WHERE servidorId = ?''',
                    [
                      categoria.nombre,
                      DateTime.now().toIso8601String(),
                      categoria.id
                    ]
                );
                print('Categoría actualizada desde servidor: ${categoria.nombre}');
              }
            }
          }

          // Eliminar categorías que ya no existen en el servidor
          await txn.rawDelete('''
          DELETE FROM categorias 
          WHERE verificado = 0 
            AND sincronizado = 1 
            AND id NOT IN (
              SELECT id_local FROM cambios_pendientes 
              WHERE tabla = 'categorias'
            )
        ''');
        } catch (e) {
          print('Error al sincronizar con servidor: $e');
          throw Exception('Error al sincronizar con servidor: $e');
        }
      });

      print('Sincronización completada exitosamente');
    } catch (e) {
      print('Error en sincronización: $e');
      rethrow;
    }
  }

  Future<void> _procesarCreacionPendiente(
      Database db,
      int cambioId,
      int? idLocal,
      CategoriaModel datos
      ) async {
    if (idLocal == null) return;

    try {
      final apiResponse = await _apiService.createCategoria(datos.toMap());

      await db.transaction((txn) async {
        await txn.rawUpdate(
            '''UPDATE categorias 
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
      });
    } catch (e) {
      print('Error al procesar creación pendiente: $e');
    }
  }



  Future<void> _procesarEliminacionPendiente(
      Database db,
      int cambioId,
      CategoriaModel datos
      ) async {
    if (datos.servidorId == null) return;

    try {
      await _apiService.deleteCategoria(datos.servidorId!);

      await db.transaction((txn) async {
        // Eliminar el cambio pendiente
        await txn.rawDelete(
            'DELETE FROM cambios_pendientes WHERE id = ?',
            [cambioId]
        );

        // Asegurarnos de que la categoría esté eliminada localmente
        await txn.rawDelete(
            'DELETE FROM categorias WHERE servidorId = ?',
            [datos.servidorId]
        );
      });

      print('Eliminación sincronizada exitosamente para categoría ID: ${datos.servidorId}');
    } catch (e) {
      print('Error al procesar eliminación pendiente: $e');
    }
  }

  Future<void> _registrarCambioPendiente(
      Database db,
      String tabla,
      String tipoOperacion,
      int? idLocal,
      CategoriaModel categoria,
      ) async {
    if (idLocal == null) {
      print('No se puede registrar cambio pendiente sin ID local');
      return;
    }

    try {
      await db.transaction((txn) async {
        await txn.rawDelete(
            '''DELETE FROM cambios_pendientes 
             WHERE tabla = ? AND id_local = ?''',
            [tabla, idLocal]
        );

        await txn.rawInsert(
            '''INSERT INTO cambios_pendientes 
             (tabla, tipo_operacion, id_local, datos, fecha)
             VALUES (?, ?, ?, ?, ?)''',
            [
              tabla,
              tipoOperacion,
              idLocal,
              categoria.toJson(),
              DateTime.now().toIso8601String(),
            ]
        );
      });

      print('Cambio pendiente registrado: $tipoOperacion para categoría $idLocal');
    } catch (e) {
      print('Error al registrar cambio pendiente: $e');
      rethrow;
    }
  }
}