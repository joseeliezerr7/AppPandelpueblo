import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Future<bool> hasConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      final hasConnection = result != ConnectivityResult.none;
      print('Estado de conectividad: ${hasConnection ? 'Conectado' : 'Sin conexión'}');
      return hasConnection;
    } catch (e) {
      print('Error al verificar conectividad: $e');
      return false;
    }
  }
}