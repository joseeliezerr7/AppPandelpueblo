import 'package:sqflite/sqflite.dart';
import '../models/pedido_model.dart';
import '../services/database_helper.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';
import 'dart:convert';

class PedidoRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ApiService _apiService;
  final ConnectivityService _connectivityService;

  PedidoRepository(this._apiService, this._connectivityService);

  // Obtener todos los pedidos locales
  Future<List<PedidoModel>> getPedidosLocales() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'pedidos',
        orderBy: 'fecha DESC',
      );

      List<PedidoModel> pedidos = [];
      for (var map in maps) {
        final pedido = PedidoModel.fromMap(map);
        final detalles = await getDetallesPedido(pedido.id!);
        pedidos.add(pedido.copyWith(detalles: detalles));
      }

      return pedidos;
    } catch (e) {
      print('Error al obtener pedidos locales: $e');
      rethrow;
    }
  }

  // Obtener pedidos por cliente
  Future<List<PedidoModel>> getPedidosPorCliente(int clienteId) async {
    final hasConnection = await _connectivityService.hasConnection();

    try {
      List<PedidoModel> pedidosServidor = [];
      List<PedidoModel> pedidosLocales = [];

      if (hasConnection) {
        // Si hay conexión, obtener del servidor
        try {
          print('✓ Hay conexión - Obteniendo pedidos desde servidor para cliente $clienteId');
          pedidosServidor = await _apiService.getPedidosPorCliente(clienteId);
        } catch (e) {
          print('Error al obtener pedidos del servidor: $e');
          // Continuar aunque falle el servidor
        }
      }

      // SIEMPRE obtener pedidos locales pendientes de sincronizar
      print('→ Obteniendo pedidos locales pendientes para cliente $clienteId');
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'pedidos',
        where: 'clienteId = ? AND sincronizado = 0',
        whereArgs: [clienteId],
        orderBy: 'fecha DESC',
      );

      for (var map in maps) {
        final pedido = PedidoModel.fromMap(map);
        final detalles = await getDetallesPedido(pedido.id!);
        pedidosLocales.add(pedido.copyWith(detalles: detalles));
      }

      print('Pedidos del servidor: ${pedidosServidor.length}');
      print('Pedidos locales pendientes: ${pedidosLocales.length}');

      // Combinar y ordenar por fecha
      final todosPedidos = [...pedidosServidor, ...pedidosLocales];
      todosPedidos.sort((a, b) {
        final fechaA = DateTime.parse(a.fecha);
        final fechaB = DateTime.parse(b.fecha);
        return fechaB.compareTo(fechaA); // Más reciente primero
      });

      return todosPedidos;
    } catch (e) {
      print('Error al obtener pedidos por cliente: $e');
      rethrow;
    }
  }

  // Obtener pedidos por pulpería
  Future<List<PedidoModel>> getPedidosPorPulperia(int pulperiaId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'pedidos',
        where: 'pulperiaId = ?',
        whereArgs: [pulperiaId],
        orderBy: 'fecha DESC',
      );

      List<PedidoModel> pedidos = [];
      for (var map in maps) {
        final pedido = PedidoModel.fromMap(map);
        final detalles = await getDetallesPedido(pedido.id!);
        pedidos.add(pedido.copyWith(detalles: detalles));
      }

      return pedidos;
    } catch (e) {
      print('Error al obtener pedidos por pulpería: $e');
      rethrow;
    }
  }

  // Obtener detalles de un pedido
  Future<List<DetallePedidoModel>> getDetallesPedido(int pedidoId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'detalles_pedido',
        where: 'pedidoId = ?',
        whereArgs: [pedidoId],
      );
      return List.generate(maps.length, (i) => DetallePedidoModel.fromMap(maps[i]));
    } catch (e) {
      print('Error al obtener detalles del pedido: $e');
      rethrow;
    }
  }

  // Obtener pedido por ID
  Future<PedidoModel?> getPedidoById(int id) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'pedidos',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        final pedido = PedidoModel.fromMap(maps.first);
        final detalles = await getDetallesPedido(id);
        return pedido.copyWith(detalles: detalles);
      }
      return null;
    } catch (e) {
      print('Error al obtener pedido por ID: $e');
      rethrow;
    }
  }

  // Crear pedido (verifica conectividad)
  Future<PedidoModel> createPedido(PedidoModel pedido, List<DetallePedidoModel> detalles) async {
    final hasConnection = await _connectivityService.hasConnection();

    print('═══════════════════════════════════════════════');
    print('CREATE PEDIDO - Inicio');
    print('Has connection: $hasConnection');
    print('ClienteId: ${pedido.clienteId}');
    print('NombreCliente: ${pedido.nombreCliente}');
    print('PulperiaId: ${pedido.pulperiaId}');
    print('═══════════════════════════════════════════════');

    try {
      if (hasConnection) {
        print('✓ Hay conexión - Creando pedido en servidor');
        try {
          // Preparar datos para el servidor
          final pedidoData = {
            'clienteId': pedido.clienteId,
            'pulperiaId': pedido.pulperiaId,
            'fecha': pedido.fecha,
            'detalles': detalles.map((d) => {
              'productoId': d.productoId,
              'cantidad': d.cantidad,
              'precio': d.precio,
            }).toList(),
          };

          print('→ Llamando API createPedido...');
          final response = await _apiService.createPedido(pedidoData);
          print('→ Respuesta recibida del servidor');

          // Crear pedido con datos del servidor
          // NO lo guardamos localmente para evitar problemas de FOREIGN KEY
          // con clientes/pulperías que solo existen en el servidor
          final pedidoServidor = PedidoModel(
            id: response['id'], // Usar ID del servidor como ID temporal
            servidorId: response['id'],
            clienteId: pedido.clienteId,
            nombreCliente: pedido.nombreCliente,
            pulperiaId: pedido.pulperiaId,
            nombrePulperia: pedido.nombrePulperia,
            fecha: pedido.fecha,
            total: (response['total'] as num).toDouble(),
            sincronizado: true,
          );

          print('✓ Pedido creado en servidor con ID: ${response['id']}');
          print('→ NO se guarda localmente para evitar FK issues');
          print('→ Retornando pedido en memoria');
          print('═══════════════════════════════════════════════');

          return pedidoServidor;
        } catch (e) {
          print('✗ Error al crear en servidor: $e');
          print('→ Guardando localmente para sincronizar después');
          final pedidoId = await _insertPedidoLocal(pedido, detalles);
          print('═══════════════════════════════════════════════');
          return pedido.copyWith(id: pedidoId);
        }
      } else {
        print('✗ Sin conexión - Creando pedido localmente');
        final pedidoId = await _insertPedidoLocal(pedido, detalles);
        print('═══════════════════════════════════════════════');
        return pedido.copyWith(id: pedidoId);
      }
    } catch (e) {
      print('Error en createPedido: $e');
      print('═══════════════════════════════════════════════');
      rethrow;
    }
  }

  // Insertar pedido local con cambios pendientes (PRIVADO)
  Future<int> _insertPedidoLocal(PedidoModel pedido, List<DetallePedidoModel> detalles) async {
    try {
      final db = await _dbHelper.database;

      // Deshabilitar foreign keys ANTES de la transacción
      // Los IDs de cliente/pulperia pueden ser del servidor y no existir localmente
      await db.execute('PRAGMA foreign_keys = OFF');

      int pedidoId = 0;

      try {
        // Iniciar transacción
        await db.transaction((txn) async {
          // Insertar pedido
          pedidoId = await txn.insert(
            'pedidos',
            pedido.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          // Insertar detalles
          for (var detalle in detalles) {
            await txn.insert(
              'detalles_pedido',
              detalle.copyWith(pedidoId: pedidoId).toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }

          // Registrar cambio pendiente
          await txn.insert('cambios_pendientes', {
            'tabla': 'pedidos',
            'tipo_operacion': 'INSERT',
            'id_local': pedidoId,
            'datos': pedido.toMap().toString(),
            'fecha': DateTime.now().toIso8601String(),
          });
        });

        print('✓ Pedido guardado localmente con ID: $pedidoId');
      } finally {
        // Reactivar foreign keys DESPUÉS de la transacción
        await db.execute('PRAGMA foreign_keys = ON');
      }

      return pedidoId;
    } catch (e) {
      print('Error al insertar pedido local: $e');
      rethrow;
    }
  }

  // Insertar pedido local SIN cambios pendientes (ya sincronizado)
  Future<int> _insertPedidoLocalSinPendiente(
    PedidoModel pedido,
    List<DetallePedidoModel> detalles,
    List<dynamic> detallesServidor,
  ) async {
    try {
      final db = await _dbHelper.database;

      int pedidoId = 0;
      await db.transaction((txn) async {
        // Insertar pedido
        pedidoId = await txn.insert(
          'pedidos',
          pedido.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Insertar detalles con servidorId
        for (int i = 0; i < detalles.length && i < detallesServidor.length; i++) {
          await txn.insert(
            'detalles_pedido',
            detalles[i].copyWith(
              pedidoId: pedidoId,
              servidorId: detallesServidor[i]['id'],
              sincronizado: true,
            ).toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });

      return pedidoId;
    } catch (e) {
      print('Error al insertar pedido sincronizado: $e');
      rethrow;
    }
  }

  // Actualizar pedido local
  Future<int> updatePedidoLocal(PedidoModel pedido, List<DetallePedidoModel> detalles) async {
    try {
      final db = await _dbHelper.database;

      int result = 0;
      await db.transaction((txn) async {
        // Actualizar pedido
        result = await txn.update(
          'pedidos',
          pedido.copyWith(sincronizado: false).toMap(),
          where: 'id = ?',
          whereArgs: [pedido.id],
        );

        // Eliminar detalles anteriores
        await txn.delete(
          'detalles_pedido',
          where: 'pedidoId = ?',
          whereArgs: [pedido.id],
        );

        // Insertar nuevos detalles
        for (var detalle in detalles) {
          await txn.insert(
            'detalles_pedido',
            detalle.copyWith(pedidoId: pedido.id).toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // Registrar cambio pendiente
        await txn.insert('cambios_pendientes', {
          'tabla': 'pedidos',
          'tipo_operacion': 'UPDATE',
          'id_local': pedido.id,
          'datos': pedido.toMap().toString(),
          'fecha': DateTime.now().toIso8601String(),
        });
      });

      return result;
    } catch (e) {
      print('Error al actualizar pedido local: $e');
      rethrow;
    }
  }

  // Eliminar pedido local
  Future<int> deletePedidoLocal(int id) async {
    try {
      final db = await _dbHelper.database;

      int result = 0;
      await db.transaction((txn) async {
        // Eliminar detalles
        await txn.delete(
          'detalles_pedido',
          where: 'pedidoId = ?',
          whereArgs: [id],
        );

        // Registrar cambio pendiente
        await txn.insert('cambios_pendientes', {
          'tabla': 'pedidos',
          'tipo_operacion': 'DELETE',
          'id_local': id,
          'datos': '{}',
          'fecha': DateTime.now().toIso8601String(),
        });

        // Eliminar pedido
        result = await txn.delete(
          'pedidos',
          where: 'id = ?',
          whereArgs: [id],
        );
      });

      return result;
    } catch (e) {
      print('Error al eliminar pedido local: $e');
      rethrow;
    }
  }

  // Sincronizar pedidos con el servidor
  Future<void> syncPedidos() async {
    try {
      print('=== Iniciando sincronización de pedidos ===');

      // 1. Primero, enviar cambios pendientes locales al servidor
      await _enviarCambiosPendientes();

      // 2. Luego, obtener pedidos del servidor y actualizar base de datos local
      final pedidosServidor = await _apiService.getPedidos();
      final db = await _dbHelper.database;

      for (var pedido in pedidosServidor) {
        // Buscar si existe localmente por servidorId
        final List<Map<String, dynamic>> existing = await db.query(
          'pedidos',
          where: 'servidorId = ?',
          whereArgs: [pedido.servidorId],
        );

        if (existing.isEmpty) {
          // Insertar nuevo pedido desde servidor
          await db.transaction((txn) async {
            final pedidoId = await txn.insert(
              'pedidos',
              pedido.copyWith(sincronizado: true).toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );

            // Insertar detalles
            if (pedido.detalles != null) {
              for (var detalle in pedido.detalles!) {
                await txn.insert(
                  'detalles_pedido',
                  detalle.copyWith(pedidoId: pedidoId).toMap(),
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
              }
            }
          });
        } else {
          // Actualizar pedido existente solo si no tiene cambios pendientes
          final idLocal = existing.first['id'] as int;
          final tieneCambiosPendientes = await _tieneCambiosPendientes(idLocal);

          if (!tieneCambiosPendientes) {
            await db.transaction((txn) async {
              // Actualizar pedido
              await txn.update(
                'pedidos',
                pedido.copyWith(id: idLocal, sincronizado: true).toMap(),
                where: 'id = ?',
                whereArgs: [idLocal],
              );

              // Eliminar detalles antiguos
              await txn.delete(
                'detalles_pedido',
                where: 'pedidoId = ?',
                whereArgs: [idLocal],
              );

              // Insertar nuevos detalles
              if (pedido.detalles != null) {
                for (var detalle in pedido.detalles!) {
                  await txn.insert(
                    'detalles_pedido',
                    detalle.copyWith(pedidoId: idLocal).toMap(),
                    conflictAlgorithm: ConflictAlgorithm.replace,
                  );
                }
              }
            });
          }
        }
      }

      print('=== Sincronización de pedidos completada ===');
    } catch (e) {
      print('Error en sincronización de pedidos: $e');
      rethrow;
    }
  }

  // Verificar si un pedido tiene cambios pendientes
  Future<bool> _tieneCambiosPendientes(int idLocal) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.query(
        'cambios_pendientes',
        where: 'tabla = ? AND id_local = ?',
        whereArgs: ['pedidos', idLocal],
      );
      return result.isNotEmpty;
    } catch (e) {
      print('Error al verificar cambios pendientes: $e');
      return false;
    }
  }

  // Enviar cambios pendientes al servidor
  Future<void> _enviarCambiosPendientes() async {
    try {
      final db = await _dbHelper.database;
      final cambios = await db.query(
        'cambios_pendientes',
        where: 'tabla = ?',
        whereArgs: ['pedidos'],
        orderBy: 'fecha ASC',
      );

      print('Cambios pendientes de pedidos: ${cambios.length}');

      for (var cambio in cambios) {
        try {
          final operacion = cambio['tipo_operacion'] as String;
          final idLocal = cambio['id_local'] as int;
          final cambioId = cambio['id'] as int;

          print('Procesando cambio: $operacion para pedido ID local $idLocal');

          if (operacion == 'INSERT') {
            // Crear pedido en el servidor
            final pedido = await getPedidoById(idLocal);
            if (pedido != null && pedido.detalles != null) {
              final pedidoData = {
                'clienteId': pedido.clienteId,
                'pulperiaId': pedido.pulperiaId,
                'fecha': pedido.fecha, // fecha ya es String
                'detalles': pedido.detalles!.map((d) => {
                  'productoId': d.productoId,
                  'cantidad': d.cantidad,
                  'precio': d.precio,
                }).toList(),
              };

              final response = await _apiService.createPedido(pedidoData);

              // Actualizar con el ID del servidor y marcar como sincronizado
              await db.update(
                'pedidos',
                {
                  'servidorId': response['id'],
                  'sincronizado': 1,
                  'last_sync': DateTime.now().toIso8601String(),
                },
                where: 'id = ?',
                whereArgs: [idLocal],
              );

              // Actualizar detalles con servidorId
              final detallesServidor = response['detalles'] as List<dynamic>;
              final detallesLocales = pedido.detalles!;

              for (int i = 0; i < detallesServidor.length && i < detallesLocales.length; i++) {
                await db.update(
                  'detalles_pedido',
                  {
                    'servidorId': detallesServidor[i]['id'],
                    'sincronizado': 1,
                    'last_sync': DateTime.now().toIso8601String(),
                  },
                  where: 'id = ?',
                  whereArgs: [detallesLocales[i].id],
                );
              }

              print('Pedido creado en servidor con ID: ${response['id']}');
            }
          } else if (operacion == 'UPDATE') {
            // Actualizar pedido en el servidor
            final pedido = await getPedidoById(idLocal);
            if (pedido != null && pedido.servidorId != null && pedido.detalles != null) {
              final pedidoData = {
                'clienteId': pedido.clienteId,
                'pulperiaId': pedido.pulperiaId,
                'fecha': pedido.fecha, // fecha ya es String
                'detalles': pedido.detalles!.map((d) => {
                  if (d.servidorId != null) 'id': d.servidorId,
                  'productoId': d.productoId,
                  'cantidad': d.cantidad,
                  'precio': d.precio,
                }).toList(),
              };

              await _apiService.updatePedido(pedido.servidorId!, pedidoData);

              // Marcar como sincronizado
              await db.update(
                'pedidos',
                {
                  'sincronizado': 1,
                  'last_sync': DateTime.now().toIso8601String(),
                },
                where: 'id = ?',
                whereArgs: [idLocal],
              );

              // Marcar detalles como sincronizados
              await db.update(
                'detalles_pedido',
                {
                  'sincronizado': 1,
                  'last_sync': DateTime.now().toIso8601String(),
                },
                where: 'pedidoId = ?',
                whereArgs: [idLocal],
              );

              print('Pedido actualizado en servidor ID: ${pedido.servidorId}');
            }
          } else if (operacion == 'DELETE') {
            // Eliminar pedido del servidor
            final datosString = cambio['datos'] as String;
            try {
              // Intentar parsear los datos para obtener el servidorId
              final datos = jsonDecode(datosString.replaceAll('\'', '"'));
              final servidorId = datos['servidorId'];

              if (servidorId != null) {
                await _apiService.deletePedido(servidorId);
                print('Pedido eliminado del servidor ID: $servidorId');
              }
            } catch (e) {
              print('No se pudo eliminar del servidor (datos inválidos): $e');
            }
          }

          // Eliminar cambio pendiente después de procesarlo exitosamente
          await db.delete(
            'cambios_pendientes',
            where: 'id = ?',
            whereArgs: [cambioId],
          );

          print('Cambio pendiente procesado y eliminado');
        } catch (e) {
          print('Error al procesar cambio pendiente (se omite): $e');
          // No eliminamos el cambio pendiente para reintentarlo después
        }
      }
    } catch (e) {
      print('Error al enviar cambios pendientes: $e');
      rethrow;
    }
  }

  // Obtener cantidad de cambios pendientes
  Future<int> getCambiosPendientes() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM cambios_pendientes WHERE tabla = ?',
        ['pedidos'],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('Error al obtener cambios pendientes: $e');
      return 0;
    }
  }
}
