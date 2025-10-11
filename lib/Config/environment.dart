// lib/config/environment.dart
class Environment {
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:8000', // Emulador Android apuntando a localhost PC
    // Si 10.0.2.2 no funciona, prueba con tu IP local: http://192.168.1.38:8000
  );

  static const int timeout = 5000; // 5 segundos

  static const bool isDevelopment = bool.fromEnvironment(
    'IS_DEVELOPMENT',
    defaultValue: true,
  );

  static String get baseUrl {
    if (isDevelopment) {
      return apiUrl;
    } else {
      return 'https://tudominio-produccion.com'; // Cambia esto por tu URL de producción
    }
  }
}