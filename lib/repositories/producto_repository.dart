import 'package:sqflite/sqflite.dart';
import '../models/producto_model.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';
import '../services/database_helper.dart';

class ProductoRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ApiService _apiService;
  final ConnectivityService _connectivityService;

  ProductoRepository(this._apiService, this._connectivityService);

  // Crear producto
  Future<ProductoModel> createProducto(ProductoModel producto) async {
    final db = await _dbHelper.database;
    final hasConnection = await _connectivityService.hasConnection();

    try {
      if (hasConnection) {
        print('Hay conexión - Intentando crear en servidor');
        try {
          final apiResponse = await _apiService.createProducto(producto.toMap());
          producto = ProductoModel.fromMap(apiResponse);
          producto.sincronizado = true;
          print('Producto creado en servidor con ID: ${producto.id}');
        } catch (e) {
          print('Error al crear en servidor: $e');
          await _crearProductoLocal(db, producto);
        }
      } else {
        print('Sin conexión - Creando producto localmente');
        await _crearProductoLocal(db, producto);
      }

      // Guardar en base de datos local
      await db.insert(
        'productos',
        producto.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return producto;
    } catch (e) {
      print('Error en createProducto: $e');
      rethrow;
    }
  }

  Future<void> _crearProductoLocal(Database db, ProductoModel producto) async {
    // Generar ID temporal negativo
    final maxId = Sqflite.firstIntValue(
        await db.rawQuery('SELECT MIN(id) FROM productos WHERE id < 0')
    ) ?? 0;
    producto.id = maxId - 1;
    producto.sincronizado = false;
    print('Producto creado localmente con ID temporal: ${producto.id}');

    // Guardar en cambios_pendientes
    await db.insert('cambios_pendientes', {
      'tabla': 'productos',
      'tipo_operacion': 'CREATE',
      'id_local': producto.id,
      'datos': producto.toJson(),
      'fecha': DateTime.now().toIso8601String(),
    });
  }

  // Sincronizar productos
  Future<void> syncProductos() async {
    print('Iniciando sincronización de productos...');

    if (!await _connectivityService.hasConnection()) {
      print('No hay conexión a internet. Sincronización cancelada.');
      return;
    }

    final db = await _dbHelper.database;

    try {
      // 1. Procesar productos no sincronizados
      print('Buscando cambios pendientes...');
      final cambiosPendientes = await db.query(
        'cambios_pendientes',
        where: 'tabla = ?',
        whereArgs: ['productos'],
        orderBy: 'fecha ASC',
      );

      print('Encontrados ${cambiosPendientes.length} cambios pendientes');

      for (var cambio in cambiosPendientes) {
        try {
          final tipoOperacion = cambio['tipo_operacion'] as String;
          final idLocal = cambio['id_local'] as int;
          final datos = cambio['datos'] as String;
          final producto = ProductoModel.fromJson(datos);

          print('Procesando cambio: $tipoOperacion para producto ${producto.nombre}');

          // Verificar conexión antes de cada operación con el servidor
          if (!await _connectivityService.hasConnection()) {
            print('Conexión perdida durante sincronización');
            return;
          }

          switch (tipoOperacion) {
            case 'CREATE':
              await _procesarCreacion(db, cambio, producto, idLocal);
              break;
            case 'UPDATE':
              await _procesarActualizacion(db, cambio, producto);
              break;
            case 'DELETE':
              await _procesarEliminacion(db, cambio, producto);
              break;
          }
        } catch (e) {
          print('Error al procesar cambio pendiente: $e');
          continue;
        }
      }

      // 2. Actualizar desde servidor solo si hay conexión
      if (await _connectivityService.hasConnection()) {
        try {
          print('Obteniendo productos del servidor...');
          final apiProductos = await _apiService.getProductos();
          await _actualizarProductosLocales(db, apiProductos);
          print('Sincronización completada exitosamente');
        } catch (e) {
          print('Error al obtener productos del servidor: $e');
        }
      }
    } catch (e) {
      print('Error durante la sincronización: $e');
    }
  }

  Future<void> _procesarCreacion(
      Database db,
      Map<String, dynamic> cambio,
      ProductoModel producto,
      int idLocal,
      ) async {
    final apiResponse = await _apiService.createProducto(producto.toMap());
    final nuevoProducto = ProductoModel.fromMap(apiResponse)..sincronizado = true;

    await db.transaction((txn) async {
      await txn.delete(
        'productos',
        where: 'id = ?',
        whereArgs: [idLocal],
      );

      await txn.insert(
        'productos',
        nuevoProducto.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await txn.delete(
        'cambios_pendientes',
        where: 'id = ?',
        whereArgs: [cambio['id']],
      );
    });

    print('Producto sincronizado con servidor. Nuevo ID: ${nuevoProducto.id}');
  }

  Future<void> _procesarActualizacion(
      Database db,
      Map<String, dynamic> cambio,
      ProductoModel producto,
      ) async {
    try {
      final apiResponse = await _apiService.updateProducto(producto.id!, producto.toMap());
      final productoActualizado = ProductoModel.fromMap(apiResponse)..sincronizado = true;

      await db.transaction((txn) async {
        await txn.update(
          'productos',
          productoActualizado.toMap(),
          where: 'id = ?',
          whereArgs: [producto.id],
        );

        await txn.delete(
          'cambios_pendientes',
          where: 'id = ?',
          whereArgs: [cambio['id']],
        );
      });

      print('Producto actualizado en servidor y marcado como sincronizado');
    } catch (e) {
      print('Error al actualizar en servidor durante sincronización: $e');
      // No lanzar excepción, continuar con siguiente cambio
    }
  }

  Future<void> _procesarEliminacion(
      Database db,
      Map<String, dynamic> cambio,
      ProductoModel producto,
      ) async {
    if (producto.id! > 0) {
      await _apiService.deleteProducto(producto.id!);
    }

    await db.transaction((txn) async {
      await txn.delete(
        'productos',
        where: 'id = ?',
        whereArgs: [producto.id],
      );

      await txn.delete(
        'cambios_pendientes',
        where: 'id = ?',
        whereArgs: [cambio['id']],
      );
    });

    print('Producto eliminado en servidor y localmente');
  }

  Future<void> _actualizarProductosLocales(
      Database db,
      List<Map<String, dynamic>> apiProductos,
      ) async {
    await db.transaction((txn) async {
      await txn.update(
        'productos',
        {'verificado': 0},
        where: null,
      );

      for (var apiProducto in apiProductos) {
        final producto = ProductoModel.fromMap(apiProducto)..sincronizado = true;

        final tieneCambiosPendientes = (await txn.query(
          'cambios_pendientes',
          where: 'tabla = ? AND tipo_operacion != ? AND id_local = ?',
          whereArgs: ['productos', 'DELETE', producto.id],
        )).isNotEmpty;

        if (!tieneCambiosPendientes) {
          await txn.insert(
            'productos',
            {...producto.toMap(), 'sincronizado': 1, 'verificado': 1},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      await txn.delete(
        'productos',
        where: 'verificado = 0 AND id > 0 AND id NOT IN (SELECT id_local FROM cambios_pendientes WHERE tabla = ?)',
        whereArgs: ['productos'],
      );
    });
  }

  // Obtener productos
// Obtener productos locales
  Future<List<ProductoModel>> getProductosLocales() async {
    final db = await _dbHelper.database;
    try {
      print('Obteniendo productos locales...');
      final List<Map<String, dynamic>> maps = await db.query('productos');
      print('Productos locales encontrados: ${maps.length}');
      return List.generate(maps.length, (i) => ProductoModel.fromMap(maps[i]));
    } catch (e) {
      print('Error al obtener productos locales: $e');
      return [];
    }
  }

// Get productos con verificación de conexión
  Future<List<ProductoModel>> getProductos() async {
    final hasConnection = await _connectivityService.hasConnection();

    if (!hasConnection) {
      print('Sin conexión - Retornando productos locales');
      return getProductosLocales();
    }

    try {
      print('Con conexión - Obteniendo productos del servidor');
      final apiProductos = await _apiService.getProductos();
      final db = await _dbHelper.database;

      // Guardar productos en la base de datos local
      await db.transaction((txn) async {
        for (var apiProducto in apiProductos) {
          final producto = ProductoModel.fromMap(apiProducto)..sincronizado = true;
          await txn.insert(
            'productos',
            producto.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });

      print('Productos actualizados localmente');
      return apiProductos.map((p) => ProductoModel.fromMap(p)).toList();
    } catch (e) {
      print('Error al obtener productos del servidor: $e');
      // Si falla la conexión al servidor, retornar productos locales
      return getProductosLocales();
    }
  }
  // Actualizar producto
  Future<ProductoModel> updateProducto(ProductoModel producto) async {
    final db = await _dbHelper.database;
    final hasConnection = await _connectivityService.hasConnection();

    try {
      if (producto.id == null) {
        throw Exception('No se puede actualizar un producto sin ID');
      }

      if (hasConnection && producto.id! > 0) {
        try {
          // Actualizar en servidor
          final apiResponse = await _apiService.updateProducto(producto.id!, producto.toMap());
          final productoActualizado = ProductoModel.fromMap(apiResponse)..sincronizado = true;

          // Actualizar en base de datos local
          await db.update(
            'productos',
            productoActualizado.toMap(),
            where: 'id = ?',
            whereArgs: [producto.id],
          );

          // Eliminar cambio pendiente
          await db.delete(
            'cambios_pendientes',
            where: 'tabla = ? AND tipo_operacion = ? AND id_local = ?',
            whereArgs: ['productos', 'UPDATE', producto.id],
          );

          return productoActualizado;
        } catch (e) {
          print('Error al actualizar en servidor: $e');
          producto.sincronizado = false;
          await _guardarCambioPendiente(db, producto);
          return producto;
        }
      } else {
        producto.sincronizado = false;
        await _guardarCambioPendiente(db, producto);
      }

      // Actualizar en base de datos local
      await db.update(
        'productos',
        producto.toMap(),
        where: 'id = ?',
        whereArgs: [producto.id],
      );

      return producto;
    } catch (e) {
      print('Error en updateProducto: $e');
      rethrow;
    }
  }

  Future<void> _guardarCambioPendiente(Database db, ProductoModel producto) async {
    // Eliminar cambios pendientes anteriores para este producto
    await db.delete(
      'cambios_pendientes',
      where: 'tabla = ? AND tipo_operacion = ? AND id_local = ?',
      whereArgs: ['productos', 'UPDATE', producto.id],
    );

    // Insertar nuevo cambio pendiente
    await db.insert('cambios_pendientes', {
      'tabla': 'productos',
      'tipo_operacion': 'UPDATE',
      'id_local': producto.id,
      'datos': producto.toJson(),
      'fecha': DateTime.now().toIso8601String(),
    });
  }

  // Eliminar producto
  Future<void> deleteProducto(int id) async {
    final db = await _dbHelper.database;
    final hasConnection = await _connectivityService.hasConnection();

    try {
      // Obtener el producto antes de eliminarlo
      final producto = await db.query(
        'productos',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (producto.isNotEmpty) {
        final productoMap = producto.first;
        final productoModel = ProductoModel.fromMap(productoMap);

        if (hasConnection && id > 0) {
          try {
            await _apiService.deleteProducto(id);
          } catch (e) {
            print('Error al eliminar en servidor: $e');
            // Registrar en cambios_pendientes si falla la eliminación en el servidor
            await _registrarCambioPendiente(
              db,
              'productos',
              'DELETE',
              id,
              productoModel.toJson(),
            );
          }
        } else {
          // Sin conexión o ID temporal, registrar en cambios_pendientes
          await _registrarCambioPendiente(
            db,
            'productos',
            'DELETE',
            id,
            productoModel.toJson(),
          );
        }

        // Eliminar de la base de datos local
        await db.delete(
          'productos',
          where: 'id = ?',
          whereArgs: [id],
        );
      } else {
        print('Producto con ID $id no encontrado en la base de datos local.');
      }
    } catch (e) {
      print('Error en deleteProducto: $e');
      rethrow;
    }
  }

  Future<void> _registrarCambioPendiente(
      Database db,
      String tabla,
      String tipoOperacion,
      int idLocal,
      String datos,
      ) async {
    await db.insert('cambios_pendientes', {
      'tabla': tabla,
      'tipo_operacion': tipoOperacion,
      'id_local': idLocal,
      'datos': datos,
      'fecha': DateTime.now().toIso8601String(),
    });
  }

}