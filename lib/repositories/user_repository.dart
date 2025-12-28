import 'package:sqflite/sqflite.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';
import '../services/database_helper.dart';

class UserRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ApiService _apiService;
  final ConnectivityService _connectivityService;

  UserRepository(this._apiService, this._connectivityService);

  // Hash de contraseña (simulando bcrypt con SHA256)
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return '\$2y\$12\$$digest';
  }

  // Obtener todos los usuarios
  Future<List<UserModel>> getAllUsers({bool forzarSync = false}) async {
    final db = await _dbHelper.database;

    // Si hay conexión y se solicita sincronizar, hacerlo primero
    if (await _connectivityService.hasConnection() && forzarSync) {
      try {
        await _syncFromServer();
      } catch (e) {
        print('Error al sincronizar desde servidor: $e');
      }
    }

    // Leer de la base de datos local
    final results = await db.query('users', orderBy: 'nombre');

    return results.map((userData) => UserModel(
      id: userData['id'] as int,
      nombre: userData['nombre'] as String,
      correoElectronico: userData['correoElectronico'] as String,
      telefono: userData['telefono'] as String? ?? '',
      permiso: userData['permiso'] as String,
      rutaId: userData['rutaId'] as int?,
      nombreRuta: userData['nombreRuta'] as String?,
    )).toList();
  }

  // Obtener usuario por ID
  Future<UserModel?> getUserById(int id) async {
    final db = await _dbHelper.database;

    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;

    final userData = results.first;
    return UserModel(
      id: userData['id'] as int,
      nombre: userData['nombre'] as String,
      correoElectronico: userData['correoElectronico'] as String,
      telefono: userData['telefono'] as String? ?? '',
      permiso: userData['permiso'] as String,
      rutaId: userData['rutaId'] as int?,
      nombreRuta: userData['nombreRuta'] as String?,
    );
  }

  // Crear un nuevo usuario
  Future<int> createUser({
    required String nombre,
    required String email,
    required String telefono,
    required String permiso,
    required String password,
    int? rutaId,
  }) async {
    final db = await _dbHelper.database;

    // Verificar si el email ya existe
    final existente = await db.query(
      'users',
      where: 'correoElectronico = ?',
      whereArgs: [email.trim()],
    );

    if (existente.isNotEmpty) {
      throw Exception('El correo electrónico ya está registrado');
    }

    // Insertar usuario localmente
    final userId = await db.insert('users', {
      'nombre': nombre.trim(),
      'correoElectronico': email.trim(),
      'telefono': telefono.trim(),
      'permiso': permiso,
      'password': _hashPassword(password),
      'rutaId': rutaId,
      'sincronizado': 0,
    });

    // Si hay conexión, intentar sincronizar con el servidor
    if (await _connectivityService.hasConnection()) {
      try {
        await _syncToServer(userId);
      } catch (e) {
        print('Error al sincronizar usuario con servidor: $e');
        // No lanzar error, el usuario se creó localmente
      }
    }

    return userId;
  }

  // Actualizar un usuario existente
  Future<void> updateUser({
    required int id,
    required String nombre,
    required String email,
    required String telefono,
    required String permiso,
    String? password,
    int? rutaId,
  }) async {
    final db = await _dbHelper.database;

    // Verificar que el usuario existe
    final usuario = await getUserById(id);
    if (usuario == null) {
      throw Exception('Usuario no encontrado');
    }

    // Verificar si el email ya existe en otro usuario
    final existente = await db.query(
      'users',
      where: 'correoElectronico = ? AND id != ?',
      whereArgs: [email.trim(), id],
    );

    if (existente.isNotEmpty) {
      throw Exception('El correo electrónico ya está registrado');
    }

    // Preparar datos para actualizar
    final Map<String, dynamic> datos = {
      'nombre': nombre.trim(),
      'correoElectronico': email.trim(),
      'telefono': telefono.trim(),
      'permiso': permiso,
      'rutaId': rutaId,
      'sincronizado': 0,
    };

    // Solo actualizar password si se proporciona uno nuevo
    if (password != null && password.isNotEmpty) {
      datos['password'] = _hashPassword(password);
    }

    await db.update(
      'users',
      datos,
      where: 'id = ?',
      whereArgs: [id],
    );

    // Si hay conexión, intentar sincronizar con el servidor
    if (await _connectivityService.hasConnection()) {
      try {
        await _syncToServer(id);
      } catch (e) {
        print('Error al sincronizar usuario con servidor: $e');
      }
    }
  }

  // Eliminar un usuario
  Future<void> deleteUser(int id) async {
    final db = await _dbHelper.database;

    // Verificar que el usuario existe
    final usuario = await getUserById(id);
    if (usuario == null) {
      throw Exception('Usuario no encontrado');
    }

    await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    // Si hay conexión, intentar eliminar del servidor
    if (await _connectivityService.hasConnection()) {
      try {
        final servidorId = await _getServidorId(id);
        if (servidorId != null) {
          await _apiService.deleteUsuario(servidorId);
        }
      } catch (e) {
        print('Error al eliminar usuario del servidor: $e');
      }
    }
  }

  // Sincronizar usuarios desde el servidor
  Future<void> _syncFromServer() async {
    if (!await _connectivityService.hasConnection()) {
      return;
    }

    final db = await _dbHelper.database;

    try {
      print('Sincronizando usuarios desde el servidor...');
      final usuarios = await _apiService.getUsuarios();

      // Preservar contraseñas locales
      final currentUsers = await db.query('users');
      final passwordMap = <int, String>{};
      for (var user in currentUsers) {
        final servidorId = user['servidorId'] as int?;
        if (servidorId != null) {
          passwordMap[servidorId] = user['password'] as String? ?? '';
        }
      }

      // Insertar o actualizar cada usuario del servidor
      for (var usuario in usuarios) {
        final password = passwordMap[usuario.id] ?? '';

        await db.insert(
          'users',
          {
            'id': usuario.id,
            'servidorId': usuario.id,
            'nombre': usuario.nombre,
            'correoElectronico': usuario.correoElectronico,
            'telefono': usuario.telefono,
            'permiso': usuario.permiso,
            'password': password,
            'rutaId': usuario.rutaId,
            'nombreRuta': usuario.nombreRuta,
            'last_sync': DateTime.now().toIso8601String(),
            'sincronizado': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      print('${usuarios.length} usuarios sincronizados desde el servidor');
    } catch (e) {
      print('Error al sincronizar usuarios desde servidor: $e');
      rethrow;
    }
  }

  // Sincronizar usuario específico al servidor
  Future<void> _syncToServer(int userId) async {
    if (!await _connectivityService.hasConnection()) {
      return;
    }

    final db = await _dbHelper.database;

    try {
      final results = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (results.isEmpty) return;

      final userData = results.first;

      // Enviar al servidor
      final response = await _apiService.createUsuario(
        nombre: userData['nombre'] as String,
        email: userData['correoElectronico'] as String,
        telefono: userData['telefono'] as String? ?? '',
        permiso: userData['permiso'] as String,
        password: userData['password'] as String,
        rutaId: userData['rutaId'] as int?,
      );

      // Actualizar con el ID del servidor
      if (response != null && response['id'] != null) {
        await db.update(
          'users',
          {
            'servidorId': response['id'],
            'sincronizado': 1,
            'last_sync': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [userId],
        );
      }
    } catch (e) {
      print('Error al sincronizar usuario al servidor: $e');
      rethrow;
    }
  }

  // Obtener ID del servidor para un usuario local
  Future<int?> _getServidorId(int localId) async {
    final db = await _dbHelper.database;

    final results = await db.query(
      'users',
      columns: ['servidorId'],
      where: 'id = ?',
      whereArgs: [localId],
    );

    if (results.isEmpty) return null;

    return results.first['servidorId'] as int?;
  }

  // Sincronizar todos los usuarios pendientes
  Future<void> syncPendingUsers() async {
    if (!await _connectivityService.hasConnection()) {
      return;
    }

    final db = await _dbHelper.database;

    final pendientes = await db.query(
      'users',
      where: 'sincronizado = ?',
      whereArgs: [0],
    );

    for (var userData in pendientes) {
      try {
        await _syncToServer(userData['id'] as int);
      } catch (e) {
        print('Error al sincronizar usuario ${userData['id']}: $e');
      }
    }
  }
}
