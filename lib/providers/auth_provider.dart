import 'package:flutter/material.dart';
import '../repositories/auth_repository.dart';
import '../models/user_model.dart';
import '../services/connectivity_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository;
  final ConnectivityService _connectivityService;
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  bool _initialized = false;

  AuthProvider({
    required AuthRepository authRepository,
    required ConnectivityService connectivityService,
  })  : _authRepository = authRepository,
        _connectivityService = connectivityService {
    _init();
  }

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null && _initialized;
  bool get isInitialized => _initialized;

  // Método copyWith para mantener el estado cuando se actualiza el provider
  AuthProvider copyWith(AuthRepository repository) {
    return AuthProvider(
      authRepository: repository,
      connectivityService: _connectivityService,
    )..updateState(
      user: _user,
      isLoading: _isLoading,
      error: _error,
      initialized: _initialized,
    );
  }

  // Método para actualizar el estado
  void updateState({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool? initialized,
  }) {
    _user = user;
    _isLoading = isLoading ?? _isLoading;
    _error = error;
    _initialized = initialized ?? _initialized;
  }

  Future<void> _init() async {
    try {
      _setLoading(true);
      await _authRepository.logout();
      _user = null;
      _initialized = true;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> checkSession() async {
    try {
      _user = await _authRepository.checkSession();
      notifyListeners();
    } catch (e) {
      _handleError('Error al verificar sesión: ${e.toString()}');
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      _setLoading(true);
      _error = null;

      // El login ya maneja la sincronización internamente si hay conexión
      _user = await _authRepository.login(email, password);

      _initialized = true;
      notifyListeners();
      return true;
    } catch (e) {
      _handleError('Error de autenticación: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    try {
      _setLoading(true);
      await _authRepository.logout();
      _user = null;
      _error = null;
      _initialized = true;
      notifyListeners();
    } catch (e) {
      _handleError('Error al cerrar sesión: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> syncUserData() async {
    if (_user == null) return;

    try {
      _setLoading(true);
      // La sincronización de datos de usuario requiere re-login
      // Por ahora, solo notificamos que se intentó
      print('Sincronización de datos de usuario requiere re-autenticación');
    } catch (e) {
      _handleError('Error al sincronizar datos: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Métodos privados para manejar el estado
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _handleError(String message) {
    _error = message;
    _isLoading = false;
    notifyListeners();
  }
}