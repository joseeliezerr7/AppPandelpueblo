# 🚀 Guía Rápida para Iniciar el Servidor

## ⚠️ IMPORTANTE: Debes tener el servidor corriendo para que la app funcione

## Pasos para Iniciar el Servidor

### 1. Abre una terminal/PowerShell en la carpeta del backend

```bash
cd D:\Programacion\Flutter\apppandelpueblo\backend-laravel
```

### 2. Verifica que tienes Composer instalado

```bash
composer --version
```

Si no lo tienes, descárgalo de: https://getcomposer.org/

### 3. Instala las dependencias (solo la primera vez)

```bash
composer install
```

### 4. Copia el archivo de configuración (solo la primera vez)

```bash
copy .env.example .env
```

O en PowerShell:
```powershell
Copy-Item .env.example .env
```

### 5. Genera la clave de aplicación (solo la primera vez)

```bash
php artisan key:generate
```

### 6. Configura la base de datos en el archivo .env

Abre el archivo `.env` y configura:

```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=pandelpueblo
DB_USERNAME=root
DB_PASSWORD=tu_password_aqui
```

### 7. Crea la base de datos en MySQL (solo la primera vez)

Abre MySQL y ejecuta:

```sql
CREATE DATABASE pandelpueblo CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 8. Ejecuta las migraciones (solo la primera vez)

```bash
php artisan migrate
```

### 9. Carga los datos de prueba (solo la primera vez)

```bash
php artisan db:seed
```

### 10. ⭐ INICIA EL SERVIDOR (¡CADA VEZ que quieras usar la app!)

```bash
php artisan serve --host=0.0.0.0 --port=5007
```

Deberías ver algo como:

```
Starting Laravel development server: http://0.0.0.0:5007
[Thu Jan 11 2024 10:30:00] PHP 8.2.0 Development Server (http://0.0.0.0:5007) started
```

### ✅ Verificar que el servidor está funcionando

Abre un navegador y visita:
```
http://localhost:5007
```

Deberías ver:
```json
{
  "message": "API Backend - App Pan del Pueblo",
  "version": "1.0.0",
  "status": "active"
}
```

## 📱 Conectar desde el Emulador Android

Si estás usando **Emulador Android**, la URL es:
```
http://10.0.2.2:5007
```

Si estás usando **Dispositivo Físico**, necesitas:
1. Conectar el dispositivo a la misma red WiFi que tu PC
2. Obtener la IP de tu PC (ejecuta `ipconfig` en Windows)
3. Usar esa IP en lugar de `localhost`, por ejemplo:
   ```
   http://192.168.1.100:5007
   ```

## 🔑 Usuarios de Prueba

Después de ejecutar `php artisan db:seed`, tendrás estos usuarios:

| Email | Contraseña | Rol |
|-------|-----------|-----|
| admin@pandelpueblo.com | admin123 | admin |
| vendedor@pandelpueblo.com | vendedor123 | vendedor |
| usuario@pandelpueblo.com | usuario123 | usuario |

## ❌ Problemas Comunes

### Error: "Class 'PDO' not found"
Necesitas habilitar PDO en PHP. Edita `php.ini` y descomenta:
```
extension=pdo_mysql
```

### Error: "Access denied for user"
Verifica las credenciales de MySQL en el archivo `.env`

### Error: "bootstrap/cache directory must be writable"
Ya está solucionado, pero si aparece, ejecuta:
```bash
mkdir -p bootstrap/cache
chmod -R 775 bootstrap/cache
```

### Puerto 5007 ocupado
Cambia el puerto:
```bash
php artisan serve --host=0.0.0.0 --port=8000
```
Y actualiza la URL en Flutter

## 🛑 Detener el Servidor

Presiona `Ctrl+C` en la terminal donde está corriendo

---

**¡RECUERDA!** El servidor debe estar corriendo mientras usas la app Flutter.
