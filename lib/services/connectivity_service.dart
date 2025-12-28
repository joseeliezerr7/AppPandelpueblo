import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final String? _serverUrl;
  DateTime? _lastCheck;
  bool? _lastResult;

  ConnectivityService({String? serverUrl}) : _serverUrl = serverUrl;

  /// Verifica si hay conexión de red (básica)
  Future<bool> hasNetworkConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      final hasConnection = result.any((r) => r != ConnectivityResult.none);
      return hasConnection;
    } catch (e) {
      print('Error al verificar conectividad de red: $e');
      return false;
    }
  }

  /// Verifica si hay conexión REAL al servidor (más confiable)
  Future<bool> hasConnection() async {
    try {
      // Cachear resultado por 5 segundos para evitar verificaciones muy frecuentes
      if (_lastCheck != null && _lastResult != null) {
        final timeSinceLastCheck = DateTime.now().difference(_lastCheck!);
        if (timeSinceLastCheck.inSeconds < 5) {
          return _lastResult!;
        }
      }

      // Primero verificar conexión de red básica
      final hasNetwork = await hasNetworkConnection();
      if (!hasNetwork) {
        _lastCheck = DateTime.now();
        _lastResult = false;
        print('Estado de conectividad: Sin conexión de red');
        return false;
      }

      // Si se proporcionó URL del servidor, verificar conexión real
      if (_serverUrl != null) {
        try {
          final uri = Uri.parse('$_serverUrl/api/ping');
          final response = await http.get(uri).timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw Exception('Timeout al conectar con servidor');
            },
          );

          final serverReachable = response.statusCode < 500;
          _lastCheck = DateTime.now();
          _lastResult = serverReachable;

          print('Estado de conectividad: ${serverReachable ? 'Conectado al servidor' : 'Servidor no disponible'}');
          return serverReachable;
        } catch (e) {
          print('Servidor no alcanzable: $e');
          _lastCheck = DateTime.now();
          _lastResult = false;
          return false;
        }
      }

      // Si no hay URL de servidor, solo devolver estado de red
      _lastCheck = DateTime.now();
      _lastResult = true;
      print('Estado de conectividad: Conectado (sin verificar servidor)');
      return true;
    } catch (e) {
      print('Error al verificar conectividad: $e');
      _lastCheck = DateTime.now();
      _lastResult = false;
      return false;
    }
  }

  /// Invalida el caché de conectividad para forzar una nueva verificación
  void invalidateCache() {
    _lastCheck = null;
    _lastResult = null;
  }
}