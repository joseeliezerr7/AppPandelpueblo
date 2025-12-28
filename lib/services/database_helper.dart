import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io';

class DatabaseHelper {
  static const _databaseName = "PanDelPueblo.db";
  static const _databaseVersion = 13;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  static bool _initialized = false;

  static void _initializeDatabaseFactory() {
    if (!_initialized) {
      if (Platform.isWindows || Platform.isLinux) {
        // Inicializar FFI para Windows y Linux
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
      _initialized = true;
    }
  }

  Future<Database> get database async {
    _initializeDatabaseFactory();
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      _initializeDatabaseFactory();

      // Obtener el path de la base de datos según la plataforma
      String path;
      if (Platform.isWindows || Platform.isLinux) {
        // Para Windows/Linux usar un path local
        final directory = Directory.current;
        path = join(directory.path, _databaseName);
      } else {
        // Para móviles usar getDatabasesPath
        path = join(await getDatabasesPath(), _databaseName);
      }

      print('Inicializando base de datos en: $path');

      // Asegurarse de que el directorio existe
      Directory dir = Directory(dirname(path));
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      // Abrir la base de datos con configuración simplificada
      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: (db) async {
          await db.rawQuery('PRAGMA foreign_keys = ON');
          print('Base de datos abierta y configurada correctamente');
        },
        singleInstance: true,
      );
    } catch (e, stackTrace) {
      print('Error inicializando base de datos: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      await db.transaction((txn) async {
        // Tabla de usuarios
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            servidorId INTEGER,
            nombre TEXT NOT NULL,
            correoElectronico TEXT UNIQUE NOT NULL,
            telefono TEXT,
            permiso TEXT NOT NULL,
            password TEXT NOT NULL,
            token TEXT,
            rutaId INTEGER,
            nombreRuta TEXT,
            last_sync TEXT,
            sincronizado INTEGER DEFAULT 0,
            FOREIGN KEY (rutaId) REFERENCES rutas (id)
          )
        ''');

        // Tabla de productos
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS productos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            precioCompra REAL NOT NULL,
            precioVenta REAL NOT NULL,
            cantidad INTEGER NOT NULL,
            categoriaId INTEGER,
            sincronizado INTEGER DEFAULT 0,
            verificado INTEGER DEFAULT 1
          )
        ''');

        // Tabla de categorías
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS categorias (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            sincronizado INTEGER DEFAULT 0,
            servidorId INTEGER,
            last_sync TEXT,
            verificado INTEGER DEFAULT 1
          )
        ''');
        await txn.execute('''
  CREATE TABLE IF NOT EXISTS rutas (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    cantidadPulperias INTEGER DEFAULT 0,
    cantidadClientes INTEGER DEFAULT 0,
    sincronizado INTEGER DEFAULT 0,
    servidorId INTEGER,
    last_sync TEXT,
    verificado INTEGER DEFAULT 1
  )
''');

        // Tabla de pulperías
        await txn.execute('''
  CREATE TABLE IF NOT EXISTS pulperias (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    direccion TEXT,
    telefono TEXT,
    rutaId INTEGER,
    nombreRuta TEXT,
    orden INTEGER DEFAULT 0,
    cantidadClientes INTEGER DEFAULT 0,
    visitado INTEGER DEFAULT 0,
    fechaVisita TEXT,
    sincronizado INTEGER DEFAULT 0,
    servidorId INTEGER,
    last_sync TEXT,
    verificado INTEGER DEFAULT 1,
    FOREIGN KEY (rutaId) REFERENCES rutas (id)
  )
''');

        // Tabla de clientes
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS clientes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            direccion TEXT,
            telefono TEXT,
            pulperiaId INTEGER,
            nombrePulperia TEXT,
            latitude REAL,
            longitude REAL,
            usuarioId INTEGER,
            orden INTEGER,
            sincronizado INTEGER DEFAULT 0,
            servidorId INTEGER,
            last_sync TEXT,
            verificado INTEGER DEFAULT 1,
            FOREIGN KEY (pulperiaId) REFERENCES pulperias (id),
            FOREIGN KEY (usuarioId) REFERENCES users (id)
          )
        ''');

        // Tabla de cronograma de visitas (días de visita por cliente)
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS cronograma_visitas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            clienteId INTEGER NOT NULL,
            dia_semana TEXT NOT NULL,
            orden INTEGER,
            activo INTEGER DEFAULT 1,
            servidorId INTEGER,
            sincronizado INTEGER DEFAULT 0,
            last_sync TEXT,
            FOREIGN KEY (clienteId) REFERENCES clientes (id) ON DELETE CASCADE,
            UNIQUE(clienteId, dia_semana)
          )
        ''');

        // Tabla de visitas realizadas (historial de visitas)
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS visitas_clientes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            clienteId INTEGER NOT NULL,
            fecha TEXT NOT NULL,
            realizada INTEGER DEFAULT 0,
            notas TEXT,
            servidorId INTEGER,
            sincronizado INTEGER DEFAULT 0,
            last_sync TEXT,
            FOREIGN KEY (clienteId) REFERENCES clientes (id) ON DELETE CASCADE
          )
        ''');

        // Tabla de pedidos
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS pedidos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            clienteId INTEGER NOT NULL,
            nombreCliente TEXT,
            pulperiaId INTEGER,
            nombrePulperia TEXT,
            fecha TEXT NOT NULL,
            total REAL NOT NULL,
            sincronizado INTEGER DEFAULT 0,
            servidorId INTEGER,
            last_sync TEXT,
            verificado INTEGER DEFAULT 1,
            FOREIGN KEY (clienteId) REFERENCES clientes (id) ON DELETE CASCADE,
            FOREIGN KEY (pulperiaId) REFERENCES pulperias (id) ON DELETE SET NULL
          )
        ''');

        // Tabla de detalles de pedido
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS detalles_pedido (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            pedidoId INTEGER NOT NULL,
            productoId INTEGER NOT NULL,
            nombreProducto TEXT,
            cantidad INTEGER NOT NULL,
            precio REAL NOT NULL,
            sincronizado INTEGER DEFAULT 0,
            servidorId INTEGER,
            last_sync TEXT,
            FOREIGN KEY (pedidoId) REFERENCES pedidos (id),
            FOREIGN KEY (productoId) REFERENCES productos (id)
          )
        ''');

        // Tabla de cambios pendientes
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS cambios_pendientes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tabla TEXT NOT NULL,
            tipo_operacion TEXT NOT NULL,
            id_local INTEGER,
            datos TEXT NOT NULL,
            fecha TEXT NOT NULL
          )
        ''');
      });

      print('Todas las tablas creadas correctamente');
    } catch (e, stackTrace) {
      print('Error en onCreate: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      // MIGRACIÓN A VERSIÓN 13: Normalización completa
      if (oldVersion < 13) {
        print('=== Migrando a versión 13: Normalización de base de datos ===');

        // 1. Agregar nuevos campos a tabla clientes
        List<Map<String, dynamic>> clientesColumns = await db.rawQuery('PRAGMA table_info(clientes)');

        if (!clientesColumns.any((col) => col['name'] == 'latitude')) {
          await db.execute('ALTER TABLE clientes ADD COLUMN latitude REAL');
        }
        if (!clientesColumns.any((col) => col['name'] == 'longitude')) {
          await db.execute('ALTER TABLE clientes ADD COLUMN longitude REAL');
        }
        if (!clientesColumns.any((col) => col['name'] == 'usuarioId')) {
          await db.execute('ALTER TABLE clientes ADD COLUMN usuarioId INTEGER');
        }
        if (!clientesColumns.any((col) => col['name'] == 'orden')) {
          await db.execute('ALTER TABLE clientes ADD COLUMN orden INTEGER');
        }

        // 2. Crear tabla cronograma_visitas (reemplaza dia, dia2, dia3)
        await db.execute('''
          CREATE TABLE IF NOT EXISTS cronograma_visitas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            clienteId INTEGER NOT NULL,
            dia_semana TEXT NOT NULL,
            orden INTEGER,
            activo INTEGER DEFAULT 1,
            servidorId INTEGER,
            sincronizado INTEGER DEFAULT 0,
            last_sync TEXT,
            FOREIGN KEY (clienteId) REFERENCES clientes (id) ON DELETE CASCADE,
            UNIQUE(clienteId, dia_semana)
          )
        ''');

        // 3. Crear tabla visitas_clientes (reemplaza hecho, fecha)
        await db.execute('''
          CREATE TABLE IF NOT EXISTS visitas_clientes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            clienteId INTEGER NOT NULL,
            fecha TEXT NOT NULL,
            realizada INTEGER DEFAULT 0,
            notas TEXT,
            servidorId INTEGER,
            sincronizado INTEGER DEFAULT 0,
            last_sync TEXT,
            FOREIGN KEY (clienteId) REFERENCES clientes (id) ON DELETE CASCADE
          )
        ''');

        // 4. CORREGIR FK INCORRECTA EN PEDIDOS
        // Guardar datos existentes
        List<Map<String, dynamic>> pedidosExistentes = await db.query('pedidos');
        List<Map<String, dynamic>> detallesExistentes = await db.query('detalles_pedido');

        // Eliminar tablas
        await db.execute('DROP TABLE IF EXISTS detalles_pedido');
        await db.execute('DROP TABLE IF EXISTS pedidos');

        // Recrear tabla pedidos con FK CORRECTA (clienteId → clientes)
        await db.execute('''
          CREATE TABLE IF NOT EXISTS pedidos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            clienteId INTEGER NOT NULL,
            nombreCliente TEXT,
            pulperiaId INTEGER,
            nombrePulperia TEXT,
            fecha TEXT NOT NULL,
            total REAL NOT NULL,
            sincronizado INTEGER DEFAULT 0,
            servidorId INTEGER,
            last_sync TEXT,
            verificado INTEGER DEFAULT 1,
            FOREIGN KEY (clienteId) REFERENCES clientes (id) ON DELETE CASCADE,
            FOREIGN KEY (pulperiaId) REFERENCES pulperias (id) ON DELETE SET NULL
          )
        ''');

        // Recrear tabla detalles_pedido
        await db.execute('''
          CREATE TABLE IF NOT EXISTS detalles_pedido (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            pedidoId INTEGER NOT NULL,
            productoId INTEGER NOT NULL,
            nombreProducto TEXT,
            cantidad INTEGER NOT NULL,
            precio REAL NOT NULL,
            sincronizado INTEGER DEFAULT 0,
            servidorId INTEGER,
            last_sync TEXT,
            FOREIGN KEY (pedidoId) REFERENCES pedidos (id) ON DELETE CASCADE,
            FOREIGN KEY (productoId) REFERENCES productos (id) ON DELETE CASCADE
          )
        ''');

        // Restaurar datos (solo si son válidos)
        for (var pedido in pedidosExistentes) {
          try {
            await db.insert('pedidos', pedido);
          } catch (e) {
            print('Advertencia: No se pudo restaurar pedido ${pedido['id']}: $e');
          }
        }

        for (var detalle in detallesExistentes) {
          try {
            await db.insert('detalles_pedido', detalle);
          } catch (e) {
            print('Advertencia: No se pudo restaurar detalle ${detalle['id']}: $e');
          }
        }

        print('✓ Migración a versión 13 completada');
      }

      if (oldVersion < 12) {
        // Agregar rutaId y nombreRuta a la tabla users
        List<Map<String, dynamic>> columns = await db.rawQuery('PRAGMA table_info(users)');

        if (!columns.any((col) => col['name'] == 'rutaId')) {
          await db.execute('ALTER TABLE users ADD COLUMN rutaId INTEGER');
        }
        if (!columns.any((col) => col['name'] == 'nombreRuta')) {
          await db.execute('ALTER TABLE users ADD COLUMN nombreRuta TEXT');
        }
      }

      if (oldVersion < 11) {
        // Recrear tabla pedidos para cambiar FOREIGN KEY de clientes a pulperias
        if (oldVersion >= 9) {
          await db.execute('DROP TABLE IF EXISTS pedidos');
          await db.execute('DROP TABLE IF EXISTS detalles_pedido');

          // Recrear tabla pedidos
          await db.execute('''
            CREATE TABLE IF NOT EXISTS pedidos (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              clienteId INTEGER NOT NULL,
              nombreCliente TEXT,
              pulperiaId INTEGER,
              nombrePulperia TEXT,
              fecha TEXT NOT NULL,
              total REAL NOT NULL,
              sincronizado INTEGER DEFAULT 0,
              servidorId INTEGER,
              last_sync TEXT,
              verificado INTEGER DEFAULT 1,
              FOREIGN KEY (clienteId) REFERENCES pulperias (id),
              FOREIGN KEY (pulperiaId) REFERENCES pulperias (id)
            )
          ''');

          // Recrear tabla detalles_pedido
          await db.execute('''
            CREATE TABLE IF NOT EXISTS detalles_pedido (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              pedidoId INTEGER NOT NULL,
              productoId INTEGER NOT NULL,
              nombreProducto TEXT,
              cantidad INTEGER NOT NULL,
              precio REAL NOT NULL,
              sincronizado INTEGER DEFAULT 0,
              servidorId INTEGER,
              last_sync TEXT,
              FOREIGN KEY (pedidoId) REFERENCES pedidos (id),
              FOREIGN KEY (productoId) REFERENCES productos (id)
            )
          ''');
        }
      }

      if (oldVersion < 10) {
        // Verificar y actualizar estructura de tablas
        List<Map<String, dynamic>> tables = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table'"
        );

        for (var table in tables) {
          String tableName = table['name'] as String;
          if (tableName != 'android_metadata' && tableName != 'sqlite_sequence') {
            await _ensureTableStructure(db, tableName);
          }
        }
      }
    } catch (e, stackTrace) {
      print('Error en onUpgrade: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> _ensureTableStructure(Database db, String tableName) async {
    try {
      List<Map<String, dynamic>> columns = await db.rawQuery('PRAGMA table_info($tableName)');

      switch (tableName) {
        case 'categorias':
          if (!columns.any((col) => col['name'] == 'sincronizado')) {
            await db.execute('ALTER TABLE $tableName ADD COLUMN sincronizado INTEGER DEFAULT 0');
          }
          if (!columns.any((col) => col['name'] == 'verificado')) {
            await db.execute('ALTER TABLE $tableName ADD COLUMN verificado INTEGER DEFAULT 1');
          }
          break;
        case 'rutas':
          if (!columns.any((col) => col['name'] == 'sincronizado')) {
            await db.execute('ALTER TABLE $tableName ADD COLUMN sincronizado INTEGER DEFAULT 0');
          }
          if (!columns.any((col) => col['name'] == 'verificado')) {
            await db.execute('ALTER TABLE $tableName ADD COLUMN verificado INTEGER DEFAULT 1');
          }
          if (!columns.any((col) => col['name'] == 'cantidadPulperias')) {
            await db.execute('ALTER TABLE $tableName ADD COLUMN cantidadPulperias INTEGER DEFAULT 0');
          }
          if (!columns.any((col) => col['name'] == 'cantidadClientes')) {
            await db.execute('ALTER TABLE $tableName ADD COLUMN cantidadClientes INTEGER DEFAULT 0');
          }
          if (!columns.any((col) => col['name'] == 'last_sync')) {
            await db.execute('ALTER TABLE $tableName ADD COLUMN last_sync TEXT');
          }
          if (!columns.any((col) => col['name'] == 'servidorId')) {
            await db.execute('ALTER TABLE $tableName ADD COLUMN servidorId INTEGER');
          }
          break;
        case 'pulperias':
          if (!columns.any((col) => col['name'] == 'sincronizado')) {
            await db.execute('ALTER TABLE $tableName ADD COLUMN sincronizado INTEGER DEFAULT 0');
          }
          if (!columns.any((col) => col['name'] == 'verificado')) {
            await db.execute('ALTER TABLE $tableName ADD COLUMN verificado INTEGER DEFAULT 1');
          }
          if (!columns.any((col) => col['name'] == 'servidorId')) {
            await db.execute('ALTER TABLE $tableName ADD COLUMN servidorId INTEGER');
          }
          if (!columns.any((col) => col['name'] == 'last_sync')) {
            await db.execute('ALTER TABLE $tableName ADD COLUMN last_sync TEXT');
          }
          if (!columns.any((col) => col['name'] == 'visitado')) {
            await db.execute('ALTER TABLE $tableName ADD COLUMN visitado INTEGER DEFAULT 0');
          }
          if (!columns.any((col) => col['name'] == 'fechaVisita')) {
            await db.execute('ALTER TABLE $tableName ADD COLUMN fechaVisita TEXT');
          }
          break;
        case 'clientes':
          if (!columns.any((col) => col['name'] == 'pulperiaId')) {
            await db.execute('ALTER TABLE $tableName ADD COLUMN pulperiaId INTEGER');
          }
          if (!columns.any((col) => col['name'] == 'nombrePulperia')) {
            await db.execute('ALTER TABLE $tableName ADD COLUMN nombrePulperia TEXT');
          }
          if (!columns.any((col) => col['name'] == 'last_sync')) {
            await db.execute('ALTER TABLE $tableName ADD COLUMN last_sync TEXT');
          }
          if (!columns.any((col) => col['name'] == 'verificado')) {
            await db.execute('ALTER TABLE $tableName ADD COLUMN verificado INTEGER DEFAULT 1');
          }
          break;
        case 'pedidos':
          if (!columns.any((col) => col['name'] == 'nombreCliente')) {
            await db.execute('ALTER TABLE $tableName ADD COLUMN nombreCliente TEXT');
          }
          if (!columns.any((col) => col['name'] == 'pulperiaId')) {
            await db.execute('ALTER TABLE $tableName ADD COLUMN pulperiaId INTEGER');
          }
          if (!columns.any((col) => col['name'] == 'nombrePulperia')) {
            await db.execute('ALTER TABLE $tableName ADD COLUMN nombrePulperia TEXT');
          }
          if (!columns.any((col) => col['name'] == 'last_sync')) {
            await db.execute('ALTER TABLE $tableName ADD COLUMN last_sync TEXT');
          }
          if (!columns.any((col) => col['name'] == 'verificado')) {
            await db.execute('ALTER TABLE $tableName ADD COLUMN verificado INTEGER DEFAULT 1');
          }
          break;
        case 'detalles_pedido':
          if (!columns.any((col) => col['name'] == 'nombreProducto')) {
            await db.execute('ALTER TABLE $tableName ADD COLUMN nombreProducto TEXT');
          }
          if (!columns.any((col) => col['name'] == 'last_sync')) {
            await db.execute('ALTER TABLE $tableName ADD COLUMN last_sync TEXT');
          }
          break;
      }
    } catch (e) {
      print('Error asegurando estructura de $tableName: $e');
    }
  }

  Future<bool> tableExists(String tableName) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
          [tableName]
      );
      return result.isNotEmpty;
    } catch (e) {
      print('Error verificando existencia de tabla: $e');
      return false;
    }
  }

  Future<void> resetDatabase() async {
    try {
      String path = join(await getDatabasesPath(), _databaseName);
      _database = null;
      await deleteDatabase(path);
      print('Base de datos reseteada exitosamente');
    } catch (e) {
      print('Error reseteando base de datos: $e');
      rethrow;
    }
  }

  // Método para verificar el estado de la base de datos
  Future<void> checkDatabaseAccess() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT 1');
      print('Acceso a base de datos exitoso: $result');
    } catch (e) {
      print('Error accediendo a base de datos: $e');
      rethrow;
    }
  }
}