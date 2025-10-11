import 'package:dio/dio.dart';
import '../models/categoria_model.dart';
import '../models/pulperia_model.dart';
import '../models/ruta_model.dart';
import '../models/user_model.dart';
import '../models/producto_model.dart';

class ApiService {
  final Dio _dio;
  String? _token;

  ApiService({required String baseUrl}) : _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    contentType: 'application/json',
  ));

  // Método para establecer el token de autenticación
  void setToken(String token) {
    _token = token;
    _dio.options.headers['Authorization'] = 'Bearer $token';
    print('Token configurado en ApiService');
  }

  // Método para limpiar el token
  void clearToken() {
    _token = null;
    _dio.options.headers.remove('Authorization');
    print('Token eliminado de ApiService');
  }

  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('Intentando login con: $email');
      final response = await _dio.post('/api/Usuarios/Login',
          data: {
            'correoElectronico': email,
            'contrasena': password,
          }
      );

      print('Respuesta del servidor: ${response.data}');

      // Extraer token y configurarlo
      final token = response.data['access_token'] as String;
      setToken(token);

      return {
        'user': UserModel.fromJson(response.data['data']),
        'token': token,
      };
    } catch (e) {
      print('Error en login: $e');
      throw Exception('Error en la autenticación');
    }
  }

  // Productos
  Future<Map<String, dynamic>> createProducto(
      Map<String, dynamic> producto) async {
    try {
      final response = await _dio.post(
        '/api/Productos',
        data: producto,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['data'];
      } else {
        throw Exception('Error al crear producto: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al crear producto: $e');
      throw Exception('Error al crear producto');
    }
  }

  Future<Map<String, dynamic>> updateProducto(int id,
      Map<String, dynamic> producto) async {
    try {
      final response = await _dio.put(
        '/api/Productos/$id',
        data: producto,
      );

      if (response.statusCode == 200) {
        // Asegúrate de que response.data['data'] existe y es un Map
        if (response.data['data'] != null && response.data['data'] is Map) {
          return response.data['data'] as Map<String, dynamic>;
        } else {
          // Si no hay data, devuelve el producto original con sincronizado = true
          return {...producto, 'sincronizado': true};
        }
      } else {
        throw Exception('Error al actualizar producto: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al actualizar producto: $e');
      throw Exception('Error al actualizar producto');
    }
  }

  Future<List<Map<String, dynamic>>> getProductos() async {
    try {
      final response = await _dio.get('/api/Productos');

      if (response.statusCode == 200) {
        List<dynamic> data = response.data['data'];
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception('Error al obtener productos: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al obtener productos: $e');
      throw Exception('Error al obtener productos');
    }
  }

  Future<void> deleteProducto(int id) async {
    try {
      final response = await _dio.delete('/api/Productos/$id');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Error al eliminar producto: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al eliminar producto: $e');
      throw Exception('Error al eliminar producto');
    }
  }

  Future<List<CategoriaModel>> getCategorias() async {
    try {
      print('Solicitando categorías al servidor...');
      print('URL: ${_dio.options.baseUrl}/api/Categorias');

      final response = await _dio.get('/api/Categorias');
      print('Respuesta del servidor: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] as List;
        return data.map((item) =>
            CategoriaModel(
              id: item['id'],
              nombre: item['nombre'],
              sincronizado: true,
              servidorId: item['id'],
            )).toList();
      } else {
        throw Exception(
            'Error en respuesta del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en getCategorias: $e');
      throw Exception('Error al obtener categorías: $e');
    }
  }

  Future<CategoriaModel> createCategoria(Map<String, dynamic> categoria) async {
    try {
      print('Creando categoría en servidor...');
      print('Datos: $categoria');

      final response = await _dio.post(
        '/api/Categorias',
        data: categoria,
      );
      print('Respuesta del servidor: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        return CategoriaModel(
          id: data['id'],
          nombre: data['nombre'],
          sincronizado: true,
          servidorId: data['id'],
        );
      } else {
        throw Exception('Error al crear categoría: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en createCategoria: $e');
      throw Exception('Error al crear categoría: $e');
    }
  }

// En ApiService
  Future<CategoriaModel> updateCategoria(int servidorId, Map<String, dynamic> data) async {
    try {
      print('Actualizando categoría en servidor... ID: $servidorId');
      print('Datos: $data');

      // Corregir la ruta de la API
      final response = await _dio.put(
        '/api/Categorias/$servidorId', // Cambiar /categorias/ por /api/Categorias/
        data: data,
      );

      print('Respuesta del servidor: ${response.data}');

      if (response.statusCode == 200) {
        // Si el servidor devuelve datos, usarlos
        if (response.data != null && response.data['data'] != null) {
          final serverData = response.data['data'];
          return CategoriaModel(
            id: data['id'],
            servidorId: servidorId,
            nombre: serverData['nombre'] ?? data['nombre'],
            sincronizado: true,
            lastSync: DateTime.now().toIso8601String(),
            verificado: true,
          );
        } else {
          // Si no hay datos del servidor, usar los datos enviados
          return CategoriaModel(
            id: data['id'],
            servidorId: servidorId,
            nombre: data['nombre'],
            sincronizado: true,
            lastSync: DateTime.now().toIso8601String(),
            verificado: true,
          );
        }
      }

      throw Exception('Error al actualizar categoría: ${response.statusCode}');
    } catch (e) {
      print('Error en updateCategoria: $e');
      rethrow;
    }
  }

  Future<void> deleteCategoria(int id) async {
    try {
      print('Eliminando categoría $id del servidor...');
      final response = await _dio.delete('/api/Categorias/$id');

      print('Respuesta del servidor: ${response.statusCode}');

      // Aceptar tanto 200, 204 como 404 (si ya fue eliminada)
      if (response.statusCode != 200 &&
          response.statusCode != 204 &&
          response.statusCode != 404) {
        throw Exception('Error al eliminar categoría: ${response.statusCode}');
      }
    } catch (e) {
      // Si es 404, consideramos que ya está eliminada
      if (e is DioException && e.response?.statusCode == 404) {
        print('Categoría no encontrada en servidor (posiblemente ya eliminada)');
        return;
      }
      print('Error en deleteCategoria: $e');
      throw Exception('Error al eliminar categoría: $e');
    }
  }
  // En tu ApiService, añade estos métodos

  Future<List<RutaModel>> getRutas() async {
    try {
      print('Solicitando rutas al servidor...');
      final response = await _dio.get('/api/Rutas');
      print('Respuesta del servidor: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] as List;
        return data.map((item) => RutaModel(
          id: item['id'],
          nombre: item['nombre'],
          cantidadPulperias: item['cantidadPulperias'] ?? 0,
          cantidadClientes: item['cantidadClientes'] ?? 0,
          sincronizado: true,
          servidorId: item['id'],
        )).toList();
      } else {
        throw Exception('Error en respuesta del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en getRutas: $e');
      throw Exception('Error al obtener rutas: $e');
    }
  }

  Future<RutaModel> createRuta(Map<String, dynamic> ruta) async {
    try {
      print('Creando ruta en servidor...');
      print('Datos: $ruta');

      final response = await _dio.post(
        '/api/Rutas',
        data: ruta,
      );
      print('Respuesta del servidor: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        return RutaModel(
          id: data['id'],
          nombre: data['nombre'],
          cantidadPulperias: data['cantidadPulperias'] ?? 0,
          cantidadClientes: data['cantidadClientes'] ?? 0,
          sincronizado: true,
          servidorId: data['id'],
        );
      } else {
        throw Exception('Error al crear ruta: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en createRuta: $e');
      throw Exception('Error al crear ruta: $e');
    }
  }

  Future<RutaModel> updateRuta(int servidorId, Map<String, dynamic> data) async {
    try {
      print('Actualizando ruta en servidor... ID: $servidorId');
      print('Datos: $data');

      final response = await _dio.put(
        '/api/Rutas/$servidorId',
        data: data,
      );

      print('Respuesta del servidor: ${response.data}');

      if (response.statusCode == 200) {
        // Si el servidor devuelve datos, usarlos
        if (response.data != null && response.data['data'] != null) {
          final serverData = response.data['data'];
          return RutaModel(
            id: data['id'],
            servidorId: servidorId,
            nombre: serverData['nombre'],
            cantidadPulperias: serverData['cantidadPulperias'] ?? 0,
            cantidadClientes: serverData['cantidadClientes'] ?? 0,
            sincronizado: true,
            lastSync: DateTime.now().toIso8601String(),
            verificado: true,
          );
        } else {
          // Si no hay datos del servidor, usar los datos enviados
          return RutaModel(
            id: data['id'],
            servidorId: servidorId,
            nombre: data['nombre'],
            cantidadPulperias: data['cantidadPulperias'] ?? 0,
            cantidadClientes: data['cantidadClientes'] ?? 0,
            sincronizado: true,
            lastSync: DateTime.now().toIso8601String(),
            verificado: true,
          );
        }
      }

      throw Exception('Error al actualizar ruta: ${response.statusCode}');
    } catch (e) {
      print('Error en updateRuta: $e');
      rethrow;
    }
  }

  Future<void> deleteRuta(int id) async {
    try {
      print('Eliminando ruta $id del servidor...');

      final response = await _dio.delete('/api/Rutas/$id');
      print('Respuesta del servidor: ${response.statusCode}');

      if (response.statusCode != 200 &&
          response.statusCode != 204 &&
          response.statusCode != 404) {
        throw Exception('Error al eliminar ruta: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en deleteRuta: $e');
      throw Exception('Error al eliminar ruta: $e');
    }
  }
  // Agregar estos métodos en la clase ApiService

  Future<List<PulperiaModel>> getPulperias() async {
    try {
      print('Solicitando pulperías al servidor...');
      final response = await _dio.get('/api/Pulperias');
      print('Respuesta del servidor: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] as List;
        return data.map((item) => PulperiaModel(
          id: item['id'],
          nombre: item['nombre'],
          direccion: item['direccion'] ?? '',
          telefono: item['telefono'] ?? '',
          rutaId: item['rutaId'],
          nombreRuta: item['nombreRuta'],
          orden: item['orden'] ?? 0,
          cantidadClientes: item['cantidadClientes'] ?? 0,
          sincronizado: true,
          servidorId: item['id'],
        )).toList();
      } else {
        throw Exception('Error en respuesta del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en getPulperias: $e');
      throw Exception('Error al obtener pulperías: $e');
    }
  }

  Future<PulperiaModel> createPulperia(Map<String, dynamic> pulperia) async {
    try {
      print('Creando pulpería en servidor...');
      print('Datos: $pulperia');

      final response = await _dio.post(
        '/api/Pulperias',
        data: pulperia,
      );
      print('Respuesta del servidor: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        return PulperiaModel(
          id: data['id'],
          nombre: data['nombre'],
          direccion: data['direccion'] ?? '',
          telefono: data['telefono'] ?? '',
          rutaId: data['rutaId'],
          nombreRuta: data['nombreRuta'],
          orden: data['orden'] ?? 0,
          cantidadClientes: data['cantidadClientes'] ?? 0,
          sincronizado: true,
          servidorId: data['id'],
        );
      } else {
        throw Exception('Error al crear pulpería: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en createPulperia: $e');
      throw Exception('Error al crear pulpería: $e');
    }
  }

  Future<PulperiaModel> updatePulperia(int servidorId, Map<String, dynamic> data) async {
    try {
      print('Actualizando pulpería en servidor... ID: $servidorId');
      print('Datos: $data');

      final response = await _dio.put(
        '/api/Pulperias/$servidorId',
        data: data,
      );

      print('Respuesta del servidor: ${response.data}');

      if (response.statusCode == 200) {
        if (response.data != null && response.data['data'] != null) {
          final serverData = response.data['data'];
          return PulperiaModel(
            id: data['id'],
            servidorId: servidorId,
            nombre: serverData['nombre'],
            direccion: serverData['direccion'] ?? '',
            telefono: serverData['telefono'] ?? '',
            rutaId: serverData['rutaId'],
            nombreRuta: serverData['nombreRuta'],
            orden: serverData['orden'] ?? 0,
            cantidadClientes: serverData['cantidadClientes'] ?? 0,
            sincronizado: true,
            lastSync: DateTime.now().toIso8601String(),
            verificado: true,
          );
        } else {
          return PulperiaModel(
            id: data['id'],
            servidorId: servidorId,
            nombre: data['nombre'],
            direccion: data['direccion'] ?? '',
            telefono: data['telefono'] ?? '',
            rutaId: data['rutaId'],
            nombreRuta: data['nombreRuta'],
            orden: data['orden'] ?? 0,
            cantidadClientes: data['cantidadClientes'] ?? 0,
            sincronizado: true,
            lastSync: DateTime.now().toIso8601String(),
            verificado: true,
          );
        }
      }

      throw Exception('Error al actualizar pulpería: ${response.statusCode}');
    } catch (e) {
      print('Error en updatePulperia: $e');
      rethrow;
    }
  }

  Future<void> deletePulperia(int id) async {
    try {
      print('Eliminando pulpería $id del servidor...');

      final response = await _dio.delete('/api/Pulperias/$id');
      print('Respuesta del servidor: ${response.statusCode}');

      if (response.statusCode != 200 &&
          response.statusCode != 204 &&
          response.statusCode != 404) {
        throw Exception('Error al eliminar pulpería: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en deletePulperia: $e');
      throw Exception('Error al eliminar pulpería: $e');
    }
  }

}