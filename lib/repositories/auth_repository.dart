import 'package:sqflite/sqflite.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';
import '../services/database_helper.dart';

class AuthRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ApiService _apiService;
  final ConnectivityService _connectivityService;

  AuthRepository(this._apiService, this._connectivityService);

  // Login
  Future<UserModel> login(String email, String password) async {
    final db = await _dbHelper.database;
    final hasConnection = await _connectivityService.hasConnection();

    try {
      // Primero intentar login offline
      try {
        final offlineUser = await _loginOffline(db, email, password);
        print('Login offline exitoso');

        // Si hay conexión, sincronizar datos y obtener nuevo token
        if (hasConnection) {
          try {
            await syncUserInfo(offlineUser, password);
          } catch (e) {
            print('Error al sincronizar: $e');
          }
        }

        return offlineUser;
      } catch (e) {
        print('Login offline falló: $e');

        // Si hay conexión, intentar login online
        if (hasConnection) {
          print('Intentando login online');
          final loginResponse = await _apiService.login(email, password);
          final user = loginResponse['user'] as UserModel;
          final token = loginResponse['token'] as String;

          print('Token recibido: ${token.substring(0, 20)}...');

          // Guardar credenciales localmente
          await db.insert(
            'users',
            {
              'id': user.id,
              'nombre': user.nombre,
              'correoElectronico': user.correoElectronico,
              'telefono': user.telefono,
              'permiso': user.permiso,
              'password': password,
              'last_sync': DateTime.now().toIso8601String(),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          print('Usuario guardado localmente');
          return user;
        } else {
          throw Exception('Credenciales incorrectas');
        }
      }
    } catch (e) {
      print('Error en login: $e');
      throw Exception(e.toString().replaceAll('Exception:', '').trim());
    }
  }

  Future<UserModel> _loginOffline(Database db, String email, String password) async {
    print('Intentando login offline para: $email');

    final List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'correoElectronico = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (results.isEmpty) {
      throw Exception('Credenciales incorrectas');
    }

    final userData = results.first;
    print('Usuario encontrado localmente: ${userData['nombre']}');

    return UserModel(
      id: userData['id'],
      nombre: userData['nombre'],
      correoElectronico: userData['correoElectronico'],
      telefono: userData['telefono'],
      permiso: userData['permiso'],
    );
  }

  // Cerrar sesión
  Future<void> logout() async {
    final db = await _dbHelper.database;
    try {
      // Limpiar el token del ApiService
      _apiService.clearToken();
      // No eliminamos los datos para permitir login offline
      print('Sesión cerrada');
    } catch (e) {
      print('Error al cerrar sesión: $e');
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  // Verificar si hay sesión activa
  Future<UserModel?> checkSession() async {
    final db = await _dbHelper.database;
    try {
      final List<Map<String, dynamic>> results = await db.query('users');

      if (results.isEmpty) {
        return null;
      }

      final userData = results.first;
      return UserModel(
        id: userData['id'],
        nombre: userData['nombre'],
        correoElectronico: userData['correoElectronico'],
        telefono: userData['telefono'],
        permiso: userData['permiso'],
      );
    } catch (e) {
      print('Error al verificar sesión: $e');
      return null;
    }
  }

  // Sincronizar información del usuario
  Future<void> syncUserInfo(UserModel currentUser, String password) async {
    if (!await _connectivityService.hasConnection()) {
      return;
    }

    final db = await _dbHelper.database;

    try {
      final loginResponse = await _apiService.login(
        currentUser.correoElectronico,
        password,
      );

      final onlineUser = loginResponse['user'] as UserModel;

      await db.update(
        'users',
        {
          'nombre': onlineUser.nombre,
          'telefono': onlineUser.telefono,
          'permiso': onlineUser.permiso,
          'last_sync': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [currentUser.id],
      );

      print('Información de usuario sincronizada');
    } catch (e) {
      print('Error al sincronizar información del usuario: $e');
    }
  }

  // Sincronizar todos los usuarios desde el servidor
  Future<void> syncAllUsers() async {
    if (!await _connectivityService.hasConnection()) {
      print('Sin conexión - no se puede sincronizar usuarios');
      return;
    }

    final db = await _dbHelper.database;

    try {
      print('Sincronizando usuarios desde el servidor...');
      final usuarios = await _apiService.getUsuarios();

      print('Usuarios obtenidos del servidor: ${usuarios.length}');

      // Limpiar tabla de usuarios (excepto el usuario actual con sesión activa)
      // Para preservar la contraseña del usuario actual
      final currentUsers = await db.query('users');
      final passwordMap = <int, String>{};
      for (var user in currentUsers) {
        passwordMap[user['id'] as int] = user['password'] as String;
      }

      // Insertar o actualizar cada usuario del servidor
      for (var usuario in usuarios) {
        // Preservar contraseña si ya existe localmente
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

      print('${usuarios.length} usuarios sincronizados exitosamente');
    } catch (e) {
      print('Error al sincronizar usuarios: $e');
      rethrow;
    }
  }

  // Obtener todos los usuarios (priorizando servidor cuando hay conexión)
  Future<List<UserModel>> getAllUsers() async {
    final db = await _dbHelper.database;

    // Si hay conexión, sincronizar primero
    if (await _connectivityService.hasConnection()) {
      try {
        await syncAllUsers();
      } catch (e) {
        print('Error al sincronizar desde servidor, usando datos locales: $e');
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
}