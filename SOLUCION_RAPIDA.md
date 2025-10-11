# 🚨 SOLUCIÓN RÁPIDA - Error de Conexión

## El Problema
```
Error en login: DioException [connection timeout]
```

Esto significa que **la app Flutter NO puede conectarse al servidor Laravel**.

## ✅ Solución en 3 Pasos

### **PASO 1: Asegúrate que el servidor esté corriendo**

1. Ve a esta carpeta:
   ```
   D:\Programacion\Flutter\apppandelpueblo\backend-laravel
   ```

2. Haz doble clic en: **`iniciar-servidor.bat`**

3. Debe abrirse una ventana de consola negra que diga:
   ```
   Laravel development server started: http://0.0.0.0:5007
   ```

4. **¡NO CIERRES ESA VENTANA!** Déjala abierta mientras usas la app

### **PASO 2: Verifica que el servidor responda**

1. Abre un navegador (Chrome/Edge)

2. Ve a esta URL:
   ```
   http://localhost:5007
   ```

3. Deberías ver algo como:
   ```json
   {
     "message": "API Backend - App Pan del Pueblo",
     "version": "1.0.0",
     "status": "active"
   }
   ```

4. Si ves eso, ¡el servidor está funcionando! ✅

### **PASO 3: Prueba el login**

Ahora intenta hacer login en la app con:
- **Email:** `admin@pandelpueblo.com`
- **Contraseña:** `admin123`

---

## ⚠️ Si NO puedes ejecutar el servidor

Es posible que necesites instalar dependencias primero. Abre PowerShell/CMD en la carpeta `backend-laravel` y ejecuta:

```bash
# 1. Instalar dependencias
composer install

# 2. Crear archivo de configuración
copy .env.example .env

# 3. Generar clave de aplicación
php artisan key:generate

# 4. Ahora sí, inicia el servidor
php artisan serve --host=0.0.0.0 --port=5007
```

---

## 🔍 Diagnóstico Avanzado

Si todavía no funciona, ejecuta el archivo: **`probar-conexion.bat`**

Esto te dirá exactamente qué está mal.

---

## 📱 Nota sobre Emulador Android

La URL `http://10.0.2.2:5007` en el emulador Android es equivalente a `http://localhost:5007` en tu PC.

Si el navegador de tu PC puede acceder a `http://localhost:5007`, entonces tu app también debería poder conectarse.

---

## ❓ Preguntas Frecuentes

**P: ¿El servidor debe estar siempre corriendo?**
R: Sí, mientras uses la app Flutter, el servidor debe estar corriendo.

**P: ¿Puedo cerrar la ventana del servidor?**
R: No, si la cierras, el servidor se detiene y la app dejará de funcionar.

**P: ¿Qué hago si el puerto 5007 está ocupado?**
R: Cambia el puerto en el comando:
```bash
php artisan serve --host=0.0.0.0 --port=8000
```
Y actualiza la URL en Flutter (`lib/Config/environment.dart`)

**P: ¿Tengo que crear la base de datos primero?**
R: Sí, en MySQL ejecuta:
```sql
CREATE DATABASE pandelpueblo;
```
Luego ejecuta las migraciones:
```bash
php artisan migrate
php artisan db:seed
```
