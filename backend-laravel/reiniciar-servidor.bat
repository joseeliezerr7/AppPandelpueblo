@echo off
echo ================================================
echo   REINICIANDO SERVIDOR LARAVEL
echo ================================================
echo.

cd /d "%~dp0"

echo [1] Limpiando cache de Laravel...
php artisan cache:clear
php artisan config:clear
php artisan route:clear
echo OK - Cache limpiado
echo.

echo [2] Optimizando autoload de Composer...
composer dump-autoload
echo OK - Autoload optimizado
echo.

echo [3] Ejecutando seeders (si es necesario)...
php artisan db:seed --force
echo.

echo ================================================
echo   INICIANDO SERVIDOR EN PUERTO 8000
echo ================================================
echo.
echo El servidor estara disponible en:
echo   - Navegador: http://localhost:8000
echo   - Emulador Android: http://10.0.2.2:8000
echo.
echo Presiona Ctrl+C para detener el servidor
echo.

php artisan serve --host=0.0.0.0 --port=8000

pause
