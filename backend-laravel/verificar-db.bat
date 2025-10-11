@echo off
echo ================================================
echo   VERIFICACION DE BASE DE DATOS
echo ================================================
echo.

cd /d "%~dp0"

echo [1] Verificando estado de migraciones...
php artisan migrate:status
echo.

echo [2] Verificando archivos de log...
if exist "storage\logs\laravel.log" (
    echo Ultimas 50 lineas del log:
    echo.
    powershell -Command "Get-Content storage\logs\laravel.log -Tail 50"
) else (
    echo No hay archivo de log todavia
)
echo.

pause
