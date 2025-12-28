import 'package:dio/dio.dart';
import '../models/categoria_model.dart';
import '../models/pulperia_model.dart';
import '../models/ruta_model.dart';
import '../models/user_model.dart';
import '../models/producto_model.dart';
import '../models/cliente_model.dart';
import '../models/pedido_model.dart';
import '../models/cronograma_visita_model.dart';
import '../models/visita_cliente_model.dart';

class ApiService {
  final Dio _dio;
  String? _token;

  ApiService({required String baseUrl}) : _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
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
      print('Respuesta del servidor - primeros 2 registros:');
      if (response.data['data'] is List && (response.data['data'] as List).isNotEmpty) {
        print(response.data['data'].take(2).toList());
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] as List;
        return data.map((item) {
          // Debug item crudo
          if (data.indexOf(item) < 2) {
            print('DEBUG ITEM - nombre: ${item['nombre']}, cantidadPulperias: ${item['cantidadPulperias']}, cantidadClientes: ${item['cantidadClientes']}');
          }

          final ruta = RutaModel(
            id: null,  // El id local se asigna al insertar en BD
            servidorId: item['id'],
            nombre: item['nombre'],
            cantidadPulperias: (item['cantidadPulperias'] as num?)?.toInt() ?? 0,
            cantidadClientes: (item['cantidadClientes'] as num?)?.toInt() ?? 0,
            sincronizado: true,
          );
          // Debug de las primeras 2 rutas
          if (data.indexOf(item) < 2) {
            print('Ruta parseada: ${ruta.nombre} - Pulperías: ${ruta.cantidadPulperias}, Clientes: ${ruta.cantidadClientes}');
          }
          return ruta;
        }).toList();
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

  Future<List<ClienteModel>> getClientesPorRuta(int rutaId) async {
    try {
      print('Solicitando clientes de la ruta $rutaId al servidor...');
      final response = await _dio.get('/api/Rutas/$rutaId/clientes');
      print('Respuesta del servidor: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] as List;
        return data.map((item) => ClienteModel.fromJson(item)).toList();
      } else {
        throw Exception('Error en respuesta del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en getClientesPorRuta: $e');
      throw Exception('Error al obtener clientes de la ruta: $e');
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

  // Usuarios
  Future<List<UserModel>> getUsuarios() async {
    try {
      print('Solicitando usuarios al servidor...');
      final response = await _dio.get('/api/Usuarios');
      print('Respuesta del servidor: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] as List;
        return data.map((item) => UserModel(
          id: item['id'],
          nombre: item['nombre'],
          correoElectronico: item['correoElectronico'],
          telefono: item['telefono'] ?? '',
          permiso: item['permiso'],
          rutaId: item['rutaId'],
          nombreRuta: item['nombreRuta'],
        )).toList();
      } else {
        throw Exception('Error en respuesta del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en getUsuarios: $e');
      throw Exception('Error al obtener usuarios: $e');
    }
  }

  Future<Map<String, dynamic>?> createUsuario({
    required String nombre,
    required String email,
    required String telefono,
    required String permiso,
    required String password,
    int? rutaId,
  }) async {
    try {
      print('Creando usuario en servidor...');
      final data = {
        'nombre': nombre,
        'correoElectronico': email,
        'telefono': telefono,
        'permiso': permiso,
        'contrasena': password,
        if (rutaId != null) 'rutaId': rutaId,
      };
      print('Datos: $data');

      final response = await _dio.post(
        '/api/Usuarios',
        data: data,
      );
      print('Respuesta del servidor: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['data'];
      } else {
        throw Exception('Error al crear usuario: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en createUsuario: $e');
      throw Exception('Error al crear usuario: $e');
    }
  }

  Future<Map<String, dynamic>?> updateUsuario({
    required int id,
    required String nombre,
    required String email,
    required String telefono,
    required String permiso,
    String? password,
    int? rutaId,
  }) async {
    try {
      print('Actualizando usuario en servidor... ID: $id');
      final data = {
        'nombre': nombre,
        'correoElectronico': email,
        'telefono': telefono,
        'permiso': permiso,
        if (password != null && password.isNotEmpty) 'contrasena': password,
        'rutaId': rutaId,
      };
      print('Datos: $data');

      final response = await _dio.put(
        '/api/Usuarios/$id',
        data: data,
      );
      print('Respuesta del servidor: ${response.data}');

      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        throw Exception('Error al actualizar usuario: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en updateUsuario: $e');
      throw Exception('Error al actualizar usuario: $e');
    }
  }

  Future<void> deleteUsuario(int id) async {
    try {
      print('Eliminando usuario $id del servidor...');

      final response = await _dio.delete('/api/Usuarios/$id');
      print('Respuesta del servidor: ${response.statusCode}');

      if (response.statusCode != 200 &&
          response.statusCode != 204 &&
          response.statusCode != 404) {
        throw Exception('Error al eliminar usuario: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        print('Usuario no encontrado en servidor (posiblemente ya eliminado)');
        return;
      }
      print('Error en deleteUsuario: $e');
      throw Exception('Error al eliminar usuario: $e');
    }
  }

  // ==================== CLIENTES ====================

  Future<List<ClienteModel>> getClientes({int? pulperiaId}) async {
    try {
      print('Obteniendo clientes del servidor...');

      String url = '/api/Clientes';
      if (pulperiaId != null) {
        url += '?pulperiaId=$pulperiaId';
      }

      final response = await _dio.get(url);
      print('Respuesta del servidor: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => ClienteModel.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener clientes: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en getClientes: $e');
      throw Exception('Error al obtener clientes: $e');
    }
  }

  Future<Map<String, dynamic>> createCliente(Map<String, dynamic> cliente) async {
    try {
      print('Creando cliente en servidor...');
      print('Datos: $cliente');

      final response = await _dio.post(
        '/api/Clientes',
        data: cliente,
      );
      print('Respuesta del servidor: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['data'];
      } else {
        throw Exception('Error al crear cliente: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en createCliente: $e');
      throw Exception('Error al crear cliente: $e');
    }
  }

  Future<Map<String, dynamic>> updateCliente(int id, Map<String, dynamic> cliente) async {
    try {
      print('Actualizando cliente en servidor... ID: $id');
      print('Datos: $cliente');

      final response = await _dio.put(
        '/api/Clientes/$id',
        data: cliente,
      );
      print('Respuesta del servidor: ${response.data}');

      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        throw Exception('Error al actualizar cliente: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en updateCliente: $e');
      throw Exception('Error al actualizar cliente: $e');
    }
  }

  Future<void> deleteCliente(int id) async {
    try {
      print('Eliminando cliente $id del servidor...');

      final response = await _dio.delete('/api/Clientes/$id');
      print('Respuesta del servidor: ${response.statusCode}');

      if (response.statusCode != 200 &&
          response.statusCode != 204 &&
          response.statusCode != 404) {
        throw Exception('Error al eliminar cliente: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        print('Cliente no encontrado en servidor (posiblemente ya eliminado)');
        return;
      }
      print('Error en deleteCliente: $e');
      throw Exception('Error al eliminar cliente: $e');
    }
  }

  // ==================== PEDIDOS ====================

  Future<List<PedidoModel>> getPedidos({int? clienteId, int? pulperiaId}) async {
    try {
      print('Obteniendo pedidos del servidor...');

      String url = '/api/Pedidos';
      List<String> params = [];
      if (clienteId != null) params.add('clienteId=$clienteId');
      if (pulperiaId != null) params.add('pulperiaId=$pulperiaId');
      if (params.isNotEmpty) url += '?${params.join('&')}';

      final response = await _dio.get(url);
      print('Respuesta del servidor: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => PedidoModel.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener pedidos: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en getPedidos: $e');
      throw Exception('Error al obtener pedidos: $e');
    }
  }

  Future<Map<String, dynamic>> createPedido(Map<String, dynamic> pedido) async {
    try {
      print('Creando pedido en servidor...');
      print('Datos: $pedido');

      final response = await _dio.post(
        '/api/Pedidos',
        data: pedido,
      );
      print('Respuesta del servidor: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['data'];
      } else {
        throw Exception('Error al crear pedido: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en createPedido: $e');
      throw Exception('Error al crear pedido: $e');
    }
  }

  Future<Map<String, dynamic>> updatePedido(int id, Map<String, dynamic> pedido) async {
    try {
      print('Actualizando pedido en servidor... ID: $id');
      print('Datos: $pedido');

      final response = await _dio.put(
        '/api/Pedidos/$id',
        data: pedido,
      );
      print('Respuesta del servidor: ${response.data}');

      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        throw Exception('Error al actualizar pedido: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en updatePedido: $e');
      throw Exception('Error al actualizar pedido: $e');
    }
  }

  Future<void> deletePedido(int id) async {
    try {
      print('Eliminando pedido $id del servidor...');

      final response = await _dio.delete('/api/Pedidos/$id');
      print('Respuesta del servidor: ${response.statusCode}');

      if (response.statusCode != 200 &&
          response.statusCode != 204 &&
          response.statusCode != 404) {
        throw Exception('Error al eliminar pedido: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        print('Pedido no encontrado en servidor (posiblemente ya eliminado)');
        return;
      }
      print('Error en deletePedido: $e');
      throw Exception('Error al eliminar pedido: $e');
    }
  }

  // ============================================================================
  // CRONOGRAMA VISITAS
  // ============================================================================

  Future<List<dynamic>> getCronogramaVisitas({int? clienteId}) async {
    try {
      String url = '/api/CronogramaVisitas';
      if (clienteId != null) {
        url += '?clienteId=$clienteId';
      }

      final response = await _dio.get(url);
      print('Cronogramas obtenidos: ${response.data['data'].length}');
      return response.data['data'];
    } catch (e) {
      print('Error en getCronogramaVisitas: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createCronogramaVisita(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/api/CronogramaVisitas', data: data);
      return response.data['data'];
    } catch (e) {
      print('Error en createCronogramaVisita: $e');
      throw Exception('Error al crear cronograma de visita: $e');
    }
  }

  Future<void> updateCronogramaVisita(int id, Map<String, dynamic> data) async {
    try {
      await _dio.put('/api/CronogramaVisitas/$id', data: data);
    } catch (e) {
      print('Error en updateCronogramaVisita: $e');
      throw Exception('Error al actualizar cronograma de visita: $e');
    }
  }

  Future<void> deleteCronogramaVisita(int id) async {
    try {
      await _dio.delete('/api/CronogramaVisitas/$id');
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        print('Cronograma no encontrado en servidor');
        return;
      }
      print('Error en deleteCronogramaVisita: $e');
      throw Exception('Error al eliminar cronograma de visita: $e');
    }
  }

  // ============================================================================
  // VISITAS CLIENTES
  // ============================================================================

  Future<List<dynamic>> getVisitasClientes({int? clienteId, String? fechaDesde, String? fechaHasta}) async {
    try {
      String url = '/api/VisitasClientes?';
      if (clienteId != null) {
        url += 'clienteId=$clienteId&';
      }
      if (fechaDesde != null) {
        url += 'fecha_desde=$fechaDesde&';
      }
      if (fechaHasta != null) {
        url += 'fecha_hasta=$fechaHasta&';
      }

      final response = await _dio.get(url);
      print('Visitas obtenidas: ${response.data['data'].length}');
      return response.data['data'];
    } catch (e) {
      print('Error en getVisitasClientes: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createVisitaCliente(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/api/VisitasClientes', data: data);
      return response.data['data'];
    } catch (e) {
      print('Error en createVisitaCliente: $e');
      throw Exception('Error al crear visita de cliente: $e');
    }
  }

  Future<void> updateVisitaCliente(int id, Map<String, dynamic> data) async {
    try {
      await _dio.put('/api/VisitasClientes/$id', data: data);
    } catch (e) {
      print('Error en updateVisitaCliente: $e');
      throw Exception('Error al actualizar visita de cliente: $e');
    }
  }

  Future<void> deleteVisitaCliente(int id) async {
    try {
      await _dio.delete('/api/VisitasClientes/$id');
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        print('Visita no encontrada en servidor');
        return;
      }
      print('Error en deleteVisitaCliente: $e');
      throw Exception('Error al eliminar visita de cliente: $e');
    }
  }

  // ============================================================================
  // MÉTODOS PARA OBTENER DATOS POR CLIENTE
  // ============================================================================

  Future<List<CronogramaVisitaModel>> getCronogramasPorCliente(int clienteId) async {
    try {
      print('Obteniendo cronogramas del cliente $clienteId desde servidor...');
      final response = await _dio.get('/api/Clientes/$clienteId/cronogramas');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] as List;
        print('Cronogramas obtenidos: ${data.length}');
        return data.map((item) => CronogramaVisitaModel.fromJson(item)).toList();
      } else {
        throw Exception('Error al obtener cronogramas: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en getCronogramasPorCliente: $e');
      rethrow;
    }
  }

  Future<List<VisitaClienteModel>> getVisitasPorCliente(int clienteId) async {
    try {
      print('Obteniendo visitas del cliente $clienteId desde servidor...');
      final response = await _dio.get('/api/Clientes/$clienteId/visitas');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] as List;
        print('Visitas obtenidas: ${data.length}');
        return data.map((item) => VisitaClienteModel.fromJson(item)).toList();
      } else {
        throw Exception('Error al obtener visitas: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en getVisitasPorCliente: $e');
      rethrow;
    }
  }

  Future<List<PedidoModel>> getPedidosPorCliente(int clienteId) async {
    try {
      print('Obteniendo pedidos del cliente $clienteId desde servidor...');
      final response = await _dio.get('/api/Clientes/$clienteId/pedidos');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] as List;
        print('Pedidos obtenidos: ${data.length}');
        return data.map((item) => PedidoModel.fromJson(item)).toList();
      } else {
        throw Exception('Error al obtener pedidos: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en getPedidosPorCliente: $e');
      rethrow;
    }
  }

}