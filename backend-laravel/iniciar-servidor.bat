@echo off
echo =========================================
echo   Servidor Laravel - App Pan del Pueblo
echo =========================================
echo.

REM Verificar si estamos en el directorio correcto
if not exist "artisan" (
    echo ERROR: No se encuentra el archivo artisan
    echo Asegurate de ejecutar este script desde la carpeta backend-laravel
    pause
    exit /b 1
)

echo [1/3] Verificando instalacion de Composer...
composer --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Composer no esta instalado
    echo Descargalo desde: https://getcomposer.org/
    pause
    exit /b 1
)
echo OK - Composer instalado

echo.
echo [2/3] Verificando dependencias...
if not exist "vendor" (
    echo Instalando dependencias de Composer...
    composer install
    if errorlevel 1 (
        echo ERROR: Fallo la instalacion de dependencias
        pause
        exit /b 1
    )
)
echo OK - Dependencias instaladas

echo.
echo [3/3] Verificando configuracion...
if not exist ".env" (
    echo Creando archivo .env desde .env.example...
    copy .env.example .env
    echo.
    echo IMPORTANTE: Edita el archivo .env con tus credenciales de base de datos
    echo Luego ejecuta: php artisan key:generate
    echo              php artisan migrate
    echo              php artisan db:seed
    pause
)

echo.
echo =========================================
echo   INICIANDO SERVIDOR EN PUERTO 5007
echo =========================================
echo.
echo El servidor estara disponible en:
echo   - Navegador: http://localhost:5007
echo   - Emulador Android: http://10.0.2.2:5007
echo.
echo Presiona Ctrl+C para detener el servidor
echo.

php artisan serve --host=0.0.0.0 --port=5007

pause
