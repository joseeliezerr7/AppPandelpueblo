import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';

class UserProvider with ChangeNotifier {
  final UserRepository _userRepository;

  UserProvider(this._userRepository);

  List<UserModel> _usuarios = [];
  bool _isLoading = false;
  String? _error;

  List<UserModel> get usuarios => _usuarios;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Cargar todos los usuarios
  Future<void> cargarUsuarios({bool forzarSync = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _usuarios = await _userRepository.getAllUsers(forzarSync: forzarSync);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Crear un nuevo usuario
  Future<void> crearUsuario({
    required String nombre,
    required String email,
    required String telefono,
    required String permiso,
    required String password,
    int? rutaId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _userRepository.createUser(
        nombre: nombre,
        email: email,
        telefono: telefono,
        permiso: permiso,
        password: password,
        rutaId: rutaId,
      );

      await cargarUsuarios();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Actualizar un usuario existente
  Future<void> actualizarUsuario({
    required int id,
    required String nombre,
    required String email,
    required String telefono,
    required String permiso,
    String? password,
    int? rutaId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _userRepository.updateUser(
        id: id,
        nombre: nombre,
        email: email,
        telefono: telefono,
        permiso: permiso,
        password: password,
        rutaId: rutaId,
      );

      await cargarUsuarios();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Eliminar un usuario
  Future<void> eliminarUsuario(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _userRepository.deleteUser(id);
      await cargarUsuarios();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Buscar usuarios por nombre o email
  List<UserModel> buscarUsuarios(String query) {
    if (query.isEmpty) return _usuarios;

    final queryLower = query.toLowerCase();
    return _usuarios.where((usuario) {
      final nombre = usuario.nombre.toLowerCase();
      final email = usuario.correoElectronico.toLowerCase();
      return nombre.contains(queryLower) || email.contains(queryLower);
    }).toList();
  }

  // Obtener usuario por ID
  UserModel? obtenerUsuarioPorId(int id) {
    try {
      return _usuarios.firstWhere((u) => u.id == id);
    } catch (e) {
      return null;
    }
  }

  // Obtener usuarios por permiso
  List<UserModel> obtenerUsuariosPorPermiso(String permiso) {
    return _usuarios.where((u) => u.permiso == permiso).toList();
  }

  // Obtener usuarios por ruta
  List<UserModel> obtenerUsuariosPorRuta(int rutaId) {
    return _usuarios.where((u) => u.rutaId == rutaId).toList();
  }
}
