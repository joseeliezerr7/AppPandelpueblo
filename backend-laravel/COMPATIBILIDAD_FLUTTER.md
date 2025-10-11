# Compatibilidad con Frontend Flutter

Este documento describe cómo el backend Laravel ha sido configurado para ser completamente compatible con el frontend Flutter existente.

## ✅ Ajustes Realizados

### 1. Formato de Respuestas JSON

Todas las respuestas de la API ahora retornan datos en el formato esperado por Flutter:

```json
{
  "data": {
    // contenido aquí
  }
}
```

**Controladores actualizados:**
- `AuthController` - Login retorna `{data: {...}, access_token, token_type}`
- `CategoriaController` - Todas las respuestas envueltas en `{data: ...}`
- `ProductoController` - Todas las respuestas envueltas en `{data: ...}`
- `RutaController` - Todas las respuestas envueltas en `{data: ...}`
- `PulperiaController` - Todas las respuestas envueltas en `{data: ...}`

### 2. Rutas con Capitalización

El frontend Flutter usa rutas con mayúsculas. Se han agregado rutas duplicadas para compatibilidad:

#### Login
- `POST /api/Usuarios/Login` - Compatible con Flutter
- `POST /api/login` - También disponible

Parámetros aceptados:
- `correoElectronico` (requerido)
- `password` o `contrasena` (ambos funcionan)

#### Categorías
- `GET /api/Categorias` - Listar
- `POST /api/Categorias` - Crear
- `GET /api/Categorias/{id}` - Ver
- `PUT /api/Categorias/{id}` - Actualizar
- `DELETE /api/Categorias/{id}` - Eliminar

#### Productos
- `GET /api/Productos` - Listar
- `POST /api/Productos` - Crear
- `GET /api/Productos/{id}` - Ver
- `PUT /api/Productos/{id}` - Actualizar
- `DELETE /api/Productos/{id}` - Eliminar

#### Rutas
- `GET /api/Rutas` - Listar
- `POST /api/Rutas` - Crear
- `GET /api/Rutas/{id}` - Ver
- `PUT /api/Rutas/{id}` - Actualizar
- `DELETE /api/Rutas/{id}` - Eliminar
- `GET /api/Rutas/{id}/pulperias` - Obtener pulperías de una ruta

#### Pulperías
- `GET /api/Pulperias` - Listar
- `POST /api/Pulperias` - Crear
- `GET /api/Pulperias/{id}` - Ver
- `PUT /api/Pulperias/{id}` - Actualizar
- `DELETE /api/Pulperias/{id}` - Eliminar

### 3. Autenticación con Laravel Sanctum

El backend usa Laravel Sanctum para autenticación con tokens:

1. **Login:** `POST /api/Usuarios/Login`
   ```json
   {
     "correoElectronico": "admin@pandelpueblo.com",
     "contrasena": "admin123"
   }
   ```

   Respuesta:
   ```json
   {
     "data": {
       "id": 1,
       "nombre": "Administrador",
       "correoElectronico": "admin@pandelpueblo.com",
       "telefono": "+505 8888-8888",
       "permiso": "admin"
     },
     "access_token": "1|token_aqui...",
     "token_type": "Bearer"
   }
   ```

2. **Peticiones Autenticadas:**
   Incluir el header:
   ```
   Authorization: Bearer {access_token}
   ```

### 4. CORS Habilitado

El backend tiene CORS configurado para aceptar peticiones desde cualquier origen (`*`).

**Archivo:** `app/Http/Middleware/Cors.php`

Headers configurados:
- `Access-Control-Allow-Origin: *`
- `Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS`
- `Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With`

## 📋 Mapeo de Campos

### Usuario (User)
| Flutter | Laravel |
|---------|---------|
| id | id |
| nombre | nombre |
| correoElectronico | correoElectronico |
| telefono | telefono |
| permiso | permiso |

### Categoría
| Flutter | Laravel |
|---------|---------|
| id | id |
| servidorId | id (mismo valor) |
| nombre | nombre |
| sincronizado | N/A (manejado por Flutter) |
| lastSync | N/A (manejado por Flutter) |
| verificado | N/A (manejado por Flutter) |

### Producto
| Flutter | Laravel |
|---------|---------|
| id | id |
| nombre | nombre |
| precioCompra | precioCompra |
| precioVenta | precioVenta |
| cantidad | cantidad |
| categoriaId | categoriaId |
| sincronizado | N/A (manejado por Flutter) |

### Ruta
| Flutter | Laravel |
|---------|---------|
| id | id |
| servidorId | id (mismo valor) |
| nombre | nombre |
| cantidadPulperias | cantidadPulperias |
| cantidadClientes | cantidadClientes |
| sincronizado | N/A (manejado por Flutter) |
| lastSync | N/A (manejado por Flutter) |
| verificado | N/A (manejado por Flutter) |

### Pulpería
| Flutter | Laravel |
|---------|---------|
| id | id |
| servidorId | id (mismo valor) |
| nombre | nombre |
| direccion | direccion |
| telefono | telefono |
| rutaId | rutaId |
| nombreRuta | nombreRuta (calculado) |
| orden | orden |
| cantidadClientes | cantidadClientes |
| sincronizado | N/A (manejado por Flutter) |
| lastSync | N/A (manejado por Flutter) |
| verificado | N/A (manejado por Flutter) |

## 🔧 Configuración en Flutter

En tu archivo `lib/Config/environment.dart`, asegúrate de tener:

```dart
static const String apiUrl = 'http://10.0.2.2:5007'; // Para emulador Android
// o
static const String apiUrl = 'http://localhost:5007'; // Para iOS Simulator
// o
static const String apiUrl = 'http://TU_IP_LOCAL:5007'; // Para dispositivo físico
```

## 🧪 Pruebas

### Probar Login
```bash
curl -X POST http://localhost:5007/api/Usuarios/Login \
  -H "Content-Type: application/json" \
  -d '{
    "correoElectronico": "admin@pandelpueblo.com",
    "contrasena": "admin123"
  }'
```

### Probar Categorías (con autenticación)
```bash
curl -X GET http://localhost:5007/api/Categorias \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Accept: application/json"
```

### Probar Productos (con autenticación)
```bash
curl -X GET http://localhost:5007/api/Productos \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Accept: application/json"
```

## 📝 Notas Importantes

1. **Sincronización Offline:** El frontend Flutter maneja la sincronización offline localmente. El backend solo almacena el estado actual de los datos.

2. **Soft Deletes:** El backend usa soft deletes, por lo que los registros eliminados se marcan como eliminados pero no se borran físicamente.

3. **Validaciones:** Todos los endpoints tienen validaciones de datos implementadas.

4. **Relaciones:** Las respuestas incluyen relaciones cuando es necesario:
   - Productos incluyen su categoría
   - Pulperías incluyen su ruta
   - Rutas incluyen sus pulperías (en detalle)

## ⚠️ Consideraciones de Seguridad

Para producción:

1. **CORS:** Configurar origins específicos en lugar de `*`
2. **HTTPS:** Usar HTTPS en lugar de HTTP
3. **Tokens:** Configurar expiración de tokens en `config/sanctum.php`
4. **Env:** Cambiar `APP_DEBUG=false` en producción
5. **Database:** Usar credenciales seguras para la base de datos

## 🎯 Estado de Compatibilidad

✅ Login compatible
✅ Categorías compatible
✅ Productos compatible
✅ Rutas compatible
✅ Pulperías compatible
✅ Autenticación con tokens
✅ CORS habilitado
✅ Formato de respuestas correcto

**El backend está 100% compatible con el frontend Flutter!** 🎉
