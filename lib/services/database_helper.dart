import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';

class DatabaseHelper {
  static const _databaseName = "PanDelPueblo.db";
  static const _databaseVersion = 8;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      String path = join(await getDatabasesPath(), _databaseName);
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
            last_sync TEXT,
            sincronizado INTEGER DEFAULT 0
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
            sincronizado INTEGER DEFAULT 0,
            servidorId INTEGER
          )
        ''');

        // Tabla de pedidos
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS pedidos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            clienteId INTEGER NOT NULL,
            fecha TEXT NOT NULL,
            total REAL NOT NULL,
            sincronizado INTEGER DEFAULT 0,
            servidorId INTEGER,
            FOREIGN KEY (clienteId) REFERENCES clientes (id)
          )
        ''');

        // Tabla de detalles de pedido
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS detalles_pedido (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            pedidoId INTEGER NOT NULL,
            productoId INTEGER NOT NULL,
            cantidad INTEGER NOT NULL,
            precio REAL NOT NULL,
            sincronizado INTEGER DEFAULT 0,
            servidorId INTEGER,
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
      if (oldVersion < 6) {
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