@echo off
echo ================================================
echo   PRUEBA DE CONEXION - App Pan del Pueblo
echo ================================================
echo.

echo [1] Verificando que PHP esta instalado...
php --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: PHP no esta instalado o no esta en el PATH
    echo Descargalo desde: https://www.php.net/downloads
    pause
    exit /b 1
)
php --version
echo.

echo [2] Verificando puerto 5007...
netstat -an | findstr ":5007" >nul
if errorlevel 1 (
    echo ADVERTENCIA: No hay ningun servicio escuchando en el puerto 5007
    echo El servidor Laravel NO esta corriendo
) else (
    echo OK: Hay un servicio en el puerto 5007
)
echo.

echo [3] Probando conexion a localhost:5007...
curl -s http://localhost:5007 >nul 2>&1
if errorlevel 1 (
    echo ERROR: No se puede conectar a localhost:5007
    echo El servidor Laravel NO esta respondiendo
) else (
    echo OK: Servidor responde en localhost:5007
    echo.
    echo Respuesta del servidor:
    curl -s http://localhost:5007
)
echo.

echo [4] Verificando archivo .env...
if not exist ".env" (
    echo ERROR: No existe el archivo .env
    echo Ejecuta: copy .env.example .env
) else (
    echo OK: Archivo .env existe
)
echo.

echo [5] Verificando APP_KEY en .env...
findstr /C:"APP_KEY=base64" .env >nul 2>&1
if errorlevel 1 (
    echo ADVERTENCIA: APP_KEY no esta configurada
    echo Ejecuta: php artisan key:generate
) else (
    echo OK: APP_KEY esta configurada
)
echo.

echo ================================================
echo   RESUMEN DEL DIAGNOSTICO
echo ================================================
echo.
echo Si ves errores arriba, necesitas:
echo 1. Ejecutar: iniciar-servidor.bat
echo 2. Esperar a que diga "Laravel development server started"
echo 3. Dejar esa ventana abierta
echo 4. Intentar login desde la app nuevamente
echo.

pause
