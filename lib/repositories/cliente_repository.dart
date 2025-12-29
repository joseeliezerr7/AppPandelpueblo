import 'package:sqflite/sqflite.dart';
import '../models/cliente_model.dart';
import '../models/cronograma_visita_model.dart';
import '../models/visita_cliente_model.dart';
import '../services/database_helper.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';
import 'dart:convert';

class ClienteRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ApiService _apiService;
  final ConnectivityService _connectivityService;

  ClienteRepository(this._apiService, this._connectivityService);

  // Obtener todos los clientes locales
  Future<List<ClienteModel>> getClientesLocales() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'clientes',
        orderBy: 'nombre ASC',
      );
      return List.generate(maps.length, (i) => ClienteModel.fromMap(maps[i]));
    } catch (e) {
      print('Error al obtener clientes locales: $e');
      rethrow;
    }
  }

  // Obtener clientes por pulpería
  Future<List<ClienteModel>> getClientesPorPulperia(int pulperiaId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'clientes',
        where: 'pulperiaId = ?',
        whereArgs: [pulperiaId],
        orderBy: 'nombre ASC',
      );
      return List.generate(maps.length, (i) => ClienteModel.fromMap(maps[i]));
    } catch (e) {
      print('Error al obtener clientes por pulpería: $e');
      rethrow;
    }
  }

  // Obtener clientes por ruta
  Future<List<ClienteModel>> getClientesPorRuta(int rutaId) async {
    final hasConnection = await _connectivityService.hasConnection();

    try {
      if (hasConnection) {
        print('✓ Hay conexión - Obteniendo clientes de la ruta desde servidor');
        try {
          final clientes = await _apiService.getClientesPorRuta(rutaId);

          // NO guardar en base de datos local para evitar problemas de FOREIGN KEY
          // Los clientes se sincronizan mediante el método syncClientes() que maneja las dependencias correctamente

          return clientes;
        } catch (e) {
          // Si el servidor devuelve 404 (ruta no existe), intentar buscar localmente
          if (e.toString().contains('404')) {
            print('⚠ Ruta no encontrada en servidor (404) - Buscando clientes locales');
            return await _getClientesLocalesPorRuta(rutaId);
          }
          rethrow;
        }
      } else {
        print('✗ Sin conexión - Buscando clientes locales de la ruta');
        return await _getClientesLocalesPorRuta(rutaId);
      }
    } catch (e) {
      print('Error al obtener clientes por ruta: $e');
      rethrow;
    }
  }

  // Helper para obtener clientes locales por ruta
  Future<List<ClienteModel>> _getClientesLocalesPorRuta(int rutaId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''SELECT c.* FROM clientes c
         INNER JOIN pulperias p ON c.pulperiaId = p.id
         INNER JOIN rutas r ON p.rutaId = r.id
         WHERE r.servidorId = ?
         ORDER BY c.orden ASC''',
      [rutaId],
    );
    return List.generate(maps.length, (i) => ClienteModel.fromMap(maps[i]));
  }

  // Obtener cliente por ID
  Future<ClienteModel?> getClienteById(int id) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'clientes',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return ClienteModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Error al obtener cliente por ID: $e');
      rethrow;
    }
  }

  // Crear cliente (verifica conectividad)
  Future<ClienteModel> createCliente(ClienteModel cliente) async {
    final hasConnection = await _connectivityService.hasConnection();

    try {
      if (hasConnection) {
        print('✓ Hay conexión - Creando cliente en servidor');
        try {
          final clienteData = {
            'nombre': cliente.nombre,
            'direccion': cliente.direccion,
            'telefono': cliente.telefono,
            'pulperiaId': cliente.pulperiaId,
          };

          final response = await _apiService.createCliente(clienteData);

          // Crear cliente con datos del servidor
          final clienteServidor = ClienteModel(
            id: null, // Se asignará al insertar local
            servidorId: response['id'],
            nombre: cliente.nombre,
            direccion: cliente.direccion,
            telefono: cliente.telefono,
            pulperiaId: cliente.pulperiaId,
            sincronizado: true,
          );

          // Guardar localmente con servidorId
          final clienteId = await _insertClienteLocalSinPendiente(clienteServidor);

          print('✓ Cliente creado en servidor con ID: ${response['id']}');
          return clienteServidor.copyWith(id: clienteId);
        } catch (e) {
          print('✗ Error al crear en servidor: $e');
          print('→ Guardando localmente para sincronizar después');
          final clienteId = await _insertClienteLocal(cliente);
          return cliente.copyWith(id: clienteId);
        }
      } else {
        print('✗ Sin conexión - Creando cliente localmente');
        final clienteId = await _insertClienteLocal(cliente);
        return cliente.copyWith(id: clienteId);
      }
    } catch (e) {
      print('Error en createCliente: $e');
      rethrow;
    }
  }

  // Insertar cliente local con cambios pendientes (PRIVADO)
  Future<int> _insertClienteLocal(ClienteModel cliente) async {
    try {
      final db = await _dbHelper.database;
      final id = await db.insert(
        'clientes',
        cliente.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Registrar cambio pendiente
      await _registrarCambioPendiente(db, 'INSERT', id, cliente.toMap());
      return id;
    } catch (e) {
      print('Error al insertar cliente local: $e');
      rethrow;
    }
  }

  // Insertar cliente local SIN cambios pendientes (ya sincronizado)
  Future<int> _insertClienteLocalSinPendiente(ClienteModel cliente) async {
    try {
      final db = await _dbHelper.database;
      final id = await db.insert(
        'clientes',
        cliente.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return id;
    } catch (e) {
      print('Error al insertar cliente sincronizado: $e');
      rethrow;
    }
  }

  // Actualizar cliente local
  Future<int> updateClienteLocal(ClienteModel cliente) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.update(
        'clientes',
        cliente.copyWith(sincronizado: false).toMap(),
        where: 'id = ?',
        whereArgs: [cliente.id],
      );

      // Registrar cambio pendiente
      await _registrarCambioPendiente(db, 'UPDATE', cliente.id!, cliente.toMap());
      return result;
    } catch (e) {
      print('Error al actualizar cliente local: $e');
      rethrow;
    }
  }

  // Eliminar cliente local
  Future<int> deleteClienteLocal(int id) async {
    try {
      final db = await _dbHelper.database;

      // Registrar cambio pendiente
      await _registrarCambioPendiente(db, 'DELETE', id, {});

      return await db.delete(
        'clientes',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error al eliminar cliente local: $e');
      rethrow;
    }
  }

  // Sincronizar clientes con el servidor
  Future<void> syncClientes() async {
    try {
      print('=== Iniciando sincronización de clientes ===');

      // 1. Primero, enviar cambios pendientes locales al servidor
      await _enviarCambiosPendientes();

      // 2. Luego, obtener clientes del servidor y actualizar base de datos local
      final clientesServidor = await _apiService.getClientes();
      final db = await _dbHelper.database;

      for (var cliente in clientesServidor) {
        // Buscar si existe localmente por servidorId
        final List<Map<String, dynamic>> existing = await db.query(
          'clientes',
          where: 'servidorId = ?',
          whereArgs: [cliente.servidorId],
        );

        int? clienteIdLocal;

        if (existing.isEmpty) {
          // Insertar nuevo cliente desde servidor
          clienteIdLocal = await db.insert(
            'clientes',
            cliente.copyWith(sincronizado: true).toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } else {
          // Actualizar cliente existente solo si no tiene cambios pendientes
          clienteIdLocal = existing.first['id'] as int;
          final tieneCambiosPendientes = await _tieneCambiosPendientes(clienteIdLocal);

          if (!tieneCambiosPendientes) {
            await db.update(
              'clientes',
              cliente.copyWith(id: clienteIdLocal, sincronizado: true).toMap(),
              where: 'id = ?',
              whereArgs: [clienteIdLocal],
            );
          }
        }

        // Sincronizar cronogramas y visitas del cliente
        if (clienteIdLocal != null && cliente.servidorId != null) {
          await _syncCronogramasCliente(cliente.servidorId!, clienteIdLocal);
          await _syncVisitasCliente(cliente.servidorId!, clienteIdLocal);
        }
      }

      print('=== Sincronización de clientes completada ===');
    } catch (e) {
      print('Error en sincronización de clientes: $e');
      rethrow;
    }
  }

  // Verificar si un cliente tiene cambios pendientes
  Future<bool> _tieneCambiosPendientes(int idLocal) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.query(
        'cambios_pendientes',
        where: 'tabla = ? AND id_local = ?',
        whereArgs: ['clientes', idLocal],
      );
      return result.isNotEmpty;
    } catch (e) {
      print('Error al verificar cambios pendientes: $e');
      return false;
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
        'tabla': 'clientes',
        'tipo_operacion': operacion,
        'id_local': idLocal,
        'datos': datos.toString(),
        'fecha': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error al registrar cambio pendiente: $e');
    }
  }

  // Enviar cambios pendientes al servidor
  Future<void> _enviarCambiosPendientes() async {
    try {
      final db = await _dbHelper.database;
      final cambios = await db.query(
        'cambios_pendientes',
        where: 'tabla = ?',
        whereArgs: ['clientes'],
        orderBy: 'fecha ASC',
      );

      print('Cambios pendientes de clientes: ${cambios.length}');

      for (var cambio in cambios) {
        try {
          final operacion = cambio['tipo_operacion'] as String;
          final idLocal = cambio['id_local'] as int;
          final cambioId = cambio['id'] as int;

          print('Procesando cambio: $operacion para cliente ID local $idLocal');

          if (operacion == 'INSERT') {
            // Crear cliente en el servidor
            final cliente = await getClienteById(idLocal);
            if (cliente != null) {
              final clienteData = {
                'nombre': cliente.nombre,
                'direccion': cliente.direccion,
                'telefono': cliente.telefono,
                'pulperiaId': cliente.pulperiaId,
              };

              final response = await _apiService.createCliente(clienteData);

              // Actualizar con el ID del servidor y marcar como sincronizado
              await db.update(
                'clientes',
                {
                  'servidorId': response['id'],
                  'sincronizado': 1,
                  'last_sync': DateTime.now().toIso8601String(),
                },
                where: 'id = ?',
                whereArgs: [idLocal],
              );

              print('Cliente creado en servidor con ID: ${response['id']}');
            }
          } else if (operacion == 'UPDATE') {
            // Actualizar cliente en el servidor
            final cliente = await getClienteById(idLocal);
            if (cliente != null && cliente.servidorId != null) {
              final clienteData = {
                'nombre': cliente.nombre,
                'direccion': cliente.direccion,
                'telefono': cliente.telefono,
                'pulperiaId': cliente.pulperiaId,
              };

              await _apiService.updateCliente(cliente.servidorId!, clienteData);

              // Marcar como sincronizado
              await db.update(
                'clientes',
                {
                  'sincronizado': 1,
                  'last_sync': DateTime.now().toIso8601String(),
                },
                where: 'id = ?',
                whereArgs: [idLocal],
              );

              print('Cliente actualizado en servidor ID: ${cliente.servidorId}');
            }
          } else if (operacion == 'DELETE') {
            // Eliminar cliente del servidor
            final datosString = cambio['datos'] as String;
            try {
              // Intentar parsear los datos para obtener el servidorId
              final datos = jsonDecode(datosString.replaceAll('\'', '"'));
              final servidorId = datos['servidorId'];

              if (servidorId != null) {
                await _apiService.deleteCliente(servidorId);
                print('Cliente eliminado del servidor ID: $servidorId');
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
        ['clientes'],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('Error al obtener cambios pendientes: $e');
      return 0;
    }
  }

  // Sincronizar cronogramas de un cliente específico
  Future<void> _syncCronogramasCliente(int clienteServidorId, int clienteIdLocal) async {
    try {
      // Obtener cronogramas del servidor para este cliente
      final cronogramasServidor = await _apiService.getCronogramaVisitas(clienteId: clienteServidorId);
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
            cronograma.copyWith(clienteId: clienteIdLocal, sincronizado: true).toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } else {
          // Actualizar cronograma existente
          final idLocal = existing.first['id'] as int;
          await db.update(
            'cronograma_visitas',
            cronograma.copyWith(id: idLocal, clienteId: clienteIdLocal, sincronizado: true).toMap(),
            where: 'id = ?',
            whereArgs: [idLocal],
          );
        }
      }

      print('✓ Cronogramas sincronizados para cliente ID local $clienteIdLocal');
    } catch (e) {
      print('Error al sincronizar cronogramas del cliente: $e');
      // No relanzar - continuar con la sincronización de otros clientes
    }
  }

  // Sincronizar visitas de un cliente específico
  Future<void> _syncVisitasCliente(int clienteServidorId, int clienteIdLocal) async {
    try {
      // Obtener visitas del servidor para este cliente
      final visitasServidor = await _apiService.getVisitasClientes(clienteId: clienteServidorId);
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
            visita.copyWith(clienteId: clienteIdLocal, sincronizado: true).toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } else {
          // Actualizar visita existente
          final idLocal = existing.first['id'] as int;
          await db.update(
            'visitas_clientes',
            visita.copyWith(id: idLocal, clienteId: clienteIdLocal, sincronizado: true).toMap(),
            where: 'id = ?',
            whereArgs: [idLocal],
          );
        }
      }

      print('✓ Visitas sincronizadas para cliente ID local $clienteIdLocal');
    } catch (e) {
      print('Error al sincronizar visitas del cliente: $e');
      // No relanzar - continuar con la sincronización de otros clientes
    }
  }
}
