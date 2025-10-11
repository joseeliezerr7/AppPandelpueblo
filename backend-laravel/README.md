# Backend Laravel - App Pan del Pueblo

API RESTful para la aplicación móvil "App Pan del Pueblo", desarrollada con Laravel 11 y Laravel Sanctum para autenticación.

## 📋 Requisitos Previos

- PHP >= 8.2
- Composer
- MySQL >= 8.0
- Extensiones PHP: OpenSSL, PDO, Mbstring, Tokenizer, XML, Ctype, JSON, BCMath

## 🚀 Instalación

### 1. Clonar el repositorio o copiar los archivos

```bash
cd backend-laravel
```

### 2. Instalar dependencias de Composer

```bash
composer install
```

### 3. Configurar el archivo de entorno

```bash
cp .env.example .env
```

Editar el archivo `.env` y configurar la conexión a la base de datos:

```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=pandelpueblo
DB_USERNAME=root
DB_PASSWORD=tu_password
```

### 4. Generar la clave de la aplicación

```bash
php artisan key:generate
```

### 5. Crear la base de datos

Crear la base de datos en MySQL:

```sql
CREATE DATABASE pandelpueblo CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 6. Ejecutar las migraciones

```bash
php artisan migrate
```

### 7. Ejecutar los seeders (opcional - datos de prueba)

```bash
php artisan db:seed
```

### 8. Iniciar el servidor de desarrollo

```bash
php artisan serve --host=0.0.0.0 --port=5007
```

La API estará disponible en `http://localhost:5007`

## 📁 Estructura del Proyecto

```
backend-laravel/
├── app/
│   ├── Http/
│   │   ├── Controllers/
│   │   │   └── Api/
│   │   │       ├── AuthController.php
│   │   │       ├── CategoriaController.php
│   │   │       ├── ProductoController.php
│   │   │       ├── RutaController.php
│   │   │       └── PulperiaController.php
│   │   └── Middleware/
│   │       └── Cors.php
│   └── Models/
│       ├── User.php
│       ├── Categoria.php
│       ├── Producto.php
│       ├── Ruta.php
│       └── Pulperia.php
├── database/
│   ├── migrations/
│   └── seeders/
├── routes/
│   ├── api.php
│   └── web.php
└── config/
```

## 🔐 Autenticación

La API utiliza **Laravel Sanctum** para autenticación basada en tokens.

### Usuarios de prueba (después de ejecutar seeders):

| Email | Password | Rol |
|-------|----------|-----|
| admin@pandelpueblo.com | admin123 | admin |
| vendedor@pandelpueblo.com | vendedor123 | vendedor |
| usuario@pandelpueblo.com | usuario123 | usuario |

## 📡 Endpoints de la API

### Autenticación (Públicos)

- `POST /api/login` - Iniciar sesión
- `POST /api/register` - Registrar nuevo usuario

### Autenticación (Protegidos)

- `POST /api/logout` - Cerrar sesión
- `GET /api/me` - Obtener usuario autenticado

### Categorías

- `GET /api/categorias` - Listar todas las categorías
- `POST /api/categorias` - Crear nueva categoría
- `GET /api/categorias/{id}` - Obtener categoría específica
- `PUT /api/categorias/{id}` - Actualizar categoría
- `DELETE /api/categorias/{id}` - Eliminar categoría
- `GET /api/categorias/{id}/productos` - Obtener productos de una categoría

### Productos

- `GET /api/productos` - Listar todos los productos
- `POST /api/productos` - Crear nuevo producto
- `GET /api/productos/{id}` - Obtener producto específico
- `PUT /api/productos/{id}` - Actualizar producto
- `DELETE /api/productos/{id}` - Eliminar producto
- `PUT /api/productos/{id}/stock` - Actualizar stock de producto

### Rutas

- `GET /api/rutas` - Listar todas las rutas
- `POST /api/rutas` - Crear nueva ruta
- `GET /api/rutas/{id}` - Obtener ruta específica
- `PUT /api/rutas/{id}` - Actualizar ruta
- `DELETE /api/rutas/{id}` - Eliminar ruta
- `GET /api/rutas/{id}/pulperias` - Obtener pulperías de una ruta

### Pulperías

- `GET /api/pulperias` - Listar todas las pulperías
- `POST /api/pulperias` - Crear nueva pulpería
- `GET /api/pulperias/{id}` - Obtener pulpería específica
- `PUT /api/pulperias/{id}` - Actualizar pulpería
- `DELETE /api/pulperias/{id}` - Eliminar pulpería

## 🔑 Uso de la API

### Ejemplo de Login:

```bash
curl -X POST http://localhost:5007/api/login \
  -H "Content-Type: application/json" \
  -d '{
    "correoElectronico": "admin@pandelpueblo.com",
    "password": "admin123"
  }'
```

Respuesta:
```json
{
  "access_token": "1|abc123...",
  "token_type": "Bearer",
  "user": {
    "id": 1,
    "nombre": "Administrador",
    "correoElectronico": "admin@pandelpueblo.com",
    "telefono": "+505 8888-8888",
    "permiso": "admin"
  }
}
```

### Ejemplo de petición autenticada:

```bash
curl -X GET http://localhost:5007/api/productos \
  -H "Authorization: Bearer 1|abc123..." \
  -H "Accept: application/json"
```

## 🗃️ Base de Datos

### Tablas principales:

- `users` - Usuarios del sistema
- `categorias` - Categorías de productos
- `productos` - Productos del inventario
- `rutas` - Rutas de distribución
- `pulperias` - Pulperías/tiendas
- `personal_access_tokens` - Tokens de autenticación (Sanctum)

## 🛠️ Comandos Útiles

```bash
# Limpiar cachés
php artisan cache:clear
php artisan config:clear
php artisan route:clear

# Ver lista de rutas
php artisan route:list

# Refrescar base de datos (elimina todos los datos)
php artisan migrate:fresh --seed

# Crear nuevo controlador
php artisan make:controller Api/NombreController

# Crear nuevo modelo
php artisan make:model Nombre -m
```

## 📝 Notas Importantes

1. **CORS**: La configuración de CORS está habilitada para todas las origins (`*`). En producción, configurar origins específicos.

2. **Puerto**: El servidor está configurado para correr en el puerto 5007 para coincidir con la configuración del app Flutter.

3. **Soft Deletes**: Las tablas de categorías, productos, rutas y pulperías utilizan soft deletes, por lo que los registros eliminados no se borran físicamente de la base de datos.

4. **Validaciones**: Todos los endpoints tienen validaciones implementadas. Revisar los controladores para más detalles.

## 🔒 Seguridad

- Las contraseñas se hashean con bcrypt
- Los tokens de Sanctum no tienen expiración por defecto (configurable en `config/sanctum.php`)
- Se recomienda usar HTTPS en producción
- Configurar variables de entorno adecuadas para producción

## 📞 Soporte

Para problemas o preguntas, contactar al equipo de desarrollo.

---

**Desarrollado con ❤️ para App Pan del Pueblo**
