# Guía de Instalación - Backend Laravel

## 📦 Instalación Paso a Paso

### 1. Requisitos del Sistema

Asegúrate de tener instalado:

- **PHP 8.2 o superior**
  ```bash
  php -v
  ```

- **Composer** (Gestor de dependencias de PHP)
  ```bash
  composer -V
  ```
  Si no lo tienes, descárgalo de: https://getcomposer.org/

- **MySQL 8.0 o superior**
  ```bash
  mysql --version
  ```

### 2. Instalar Dependencias

Navega al directorio del backend:

```bash
cd backend-laravel
```

Instala las dependencias de Composer:

```bash
composer install
```

**Nota:** Este proceso puede tardar varios minutos la primera vez.

### 3. Configurar Variables de Entorno

Copia el archivo de ejemplo:

```bash
cp .env.example .env
```

En Windows (PowerShell):
```powershell
Copy-Item .env.example .env
```

Edita el archivo `.env` con tu editor favorito y configura:

```env
APP_NAME="App Pan del Pueblo API"
APP_ENV=local
APP_DEBUG=true
APP_URL=http://localhost:5007

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=pandelpueblo
DB_USERNAME=root
DB_PASSWORD=TU_PASSWORD_AQUI
```

### 4. Generar Clave de Aplicación

```bash
php artisan key:generate
```

Este comando generará automáticamente una clave única para tu aplicación.

### 5. Crear la Base de Datos

Conéctate a MySQL:

```bash
mysql -u root -p
```

Ejecuta el siguiente comando SQL:

```sql
CREATE DATABASE pandelpueblo CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
EXIT;
```

### 6. Ejecutar Migraciones

Crea todas las tablas en la base de datos:

```bash
php artisan migrate
```

Si te pregunta si deseas crear la base de datos, responde `yes`.

### 7. Cargar Datos de Prueba (Opcional pero Recomendado)

```bash
php artisan db:seed
```

Esto creará:
- 3 usuarios de prueba (admin, vendedor, usuario)
- 10 categorías de productos
- 5 rutas de distribución
- 10 pulperías
- 21+ productos de ejemplo

### 8. Iniciar el Servidor

```bash
php artisan serve --host=0.0.0.0 --port=5007
```

El servidor estará corriendo en: **http://localhost:5007**

Para detener el servidor, presiona `Ctrl+C`.

## ✅ Verificar Instalación

### Probar el endpoint principal:

Abre tu navegador y visita:
```
http://localhost:5007
```

Deberías ver una respuesta JSON como:
```json
{
  "message": "API Backend - App Pan del Pueblo",
  "version": "1.0.0",
  "status": "active"
}
```

### Probar el login:

Usa Postman, Insomnia o curl:

```bash
curl -X POST http://localhost:5007/api/login \
  -H "Content-Type: application/json" \
  -d "{\"correoElectronico\":\"admin@pandelpueblo.com\",\"password\":\"admin123\"}"
```

Si obtienes un token de acceso, ¡todo está funcionando correctamente! 🎉

## 🔧 Solución de Problemas Comunes

### Error: "Class 'PDO' not found"

Necesitas habilitar la extensión PDO de MySQL en PHP:

1. Abre `php.ini`
2. Busca y descomenta (quita el `;`):
   ```
   extension=pdo_mysql
   ```
3. Reinicia tu servidor web

### Error: "SQLSTATE[HY000] [1045] Access denied"

Tu usuario o contraseña de MySQL son incorrectos. Verifica:
- `DB_USERNAME` en el archivo `.env`
- `DB_PASSWORD` en el archivo `.env`

### Error: "specified key was too long"

Asegúrate de que tu archivo `AppServiceProvider.php` tenga:
```php
use Illuminate\Support\Facades\Schema;

public function boot()
{
    Schema::defaultStringLength(191);
}
```

### Puerto 5007 ya en uso

Si el puerto está ocupado, puedes usar otro:
```bash
php artisan serve --host=0.0.0.0 --port=8000
```

No olvides actualizar la configuración en tu app Flutter.

## 🚀 Comandos Útiles

```bash
# Ver todas las rutas disponibles
php artisan route:list

# Limpiar cachés
php artisan cache:clear
php artisan config:clear
php artisan route:clear

# Recrear base de datos desde cero
php artisan migrate:fresh --seed

# Verificar estado de migraciones
php artisan migrate:status
```

## 📱 Conectar con la App Flutter

En tu app Flutter, asegúrate de que la URL en `lib/Config/environment.dart` apunte a:

```dart
static const String apiUrl = 'http://10.0.2.2:5007'; // Para emulador Android
// o
static const String apiUrl = 'http://localhost:5007'; // Para iOS Simulator
```

## 🔐 Usuarios de Prueba

Después de ejecutar `php artisan db:seed`:

| Email | Password | Rol |
|-------|----------|-----|
| admin@pandelpueblo.com | admin123 | admin |
| vendedor@pandelpueblo.com | vendedor123 | vendedor |
| usuario@pandelpueblo.com | usuario123 | usuario |

## 📞 ¿Necesitas Ayuda?

Si encuentras algún problema durante la instalación:

1. Verifica que cumples todos los requisitos
2. Revisa los logs en `storage/logs/laravel.log`
3. Asegúrate de que MySQL esté corriendo
4. Verifica que el archivo `.env` esté configurado correctamente

---

**¡Feliz desarrollo! 🎉**
