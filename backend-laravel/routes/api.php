<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CategoriaController;
use App\Http\Controllers\Api\ProductoController;
use App\Http\Controllers\Api\RutaController;
use App\Http\Controllers\Api\PulperiaController;
use App\Http\Controllers\Api\ClienteController;
use App\Http\Controllers\Api\PedidoController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\CronogramaVisitaController;
use App\Http\Controllers\Api\VisitaClienteController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

// Public routes (case-insensitive)
Route::get('/ping', function () {
    return response()->json(['status' => 'ok', 'timestamp' => time()]);
});

Route::post('/login', [AuthController::class, 'login']);
Route::post('/register', [AuthController::class, 'register']);
Route::post('/Usuarios/Login', [AuthController::class, 'login']);

// Protected routes
Route::middleware('auth:sanctum')->group(function () {
    // Auth routes
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);

    // Categorias routes (lowercase)
    Route::apiResource('categorias', CategoriaController::class);
    Route::get('categorias/{id}/productos', [CategoriaController::class, 'productos']);

    // Categorias routes (capitalized - for Flutter compatibility)
    Route::get('/Categorias', [CategoriaController::class, 'index']);
    Route::post('/Categorias', [CategoriaController::class, 'store']);
    Route::get('/Categorias/{id}', [CategoriaController::class, 'show']);
    Route::put('/Categorias/{id}', [CategoriaController::class, 'update']);
    Route::delete('/Categorias/{id}', [CategoriaController::class, 'destroy']);
    Route::get('/Categorias/{id}/productos', [CategoriaController::class, 'productos']);

    // Productos routes (lowercase)
    Route::apiResource('productos', ProductoController::class);
    Route::put('productos/{id}/stock', [ProductoController::class, 'updateStock']);

    // Productos routes (capitalized - for Flutter compatibility)
    Route::get('/Productos', [ProductoController::class, 'index']);
    Route::post('/Productos', [ProductoController::class, 'store']);
    Route::get('/Productos/{id}', [ProductoController::class, 'show']);
    Route::put('/Productos/{id}', [ProductoController::class, 'update']);
    Route::delete('/Productos/{id}', [ProductoController::class, 'destroy']);
    Route::put('/Productos/{id}/stock', [ProductoController::class, 'updateStock']);

    // Rutas routes (lowercase)
    Route::apiResource('rutas', RutaController::class);
    Route::get('rutas/{id}/pulperias', [RutaController::class, 'pulperias']);
    Route::get('rutas/{id}/clientes', [RutaController::class, 'clientes']);

    // Rutas routes (capitalized - for Flutter compatibility)
    Route::get('/Rutas', [RutaController::class, 'index']);
    Route::post('/Rutas', [RutaController::class, 'store']);
    Route::get('/Rutas/{id}', [RutaController::class, 'show']);
    Route::put('/Rutas/{id}', [RutaController::class, 'update']);
    Route::delete('/Rutas/{id}', [RutaController::class, 'destroy']);
    Route::get('/Rutas/{id}/pulperias', [RutaController::class, 'pulperias']);
    Route::get('/Rutas/{id}/clientes', [RutaController::class, 'clientes']);

    // Pulperias routes (lowercase)
    Route::apiResource('pulperias', PulperiaController::class);

    // Pulperias routes (capitalized - for Flutter compatibility)
    Route::get('/Pulperias', [PulperiaController::class, 'index']);
    Route::post('/Pulperias', [PulperiaController::class, 'store']);
    Route::get('/Pulperias/{id}', [PulperiaController::class, 'show']);
    Route::put('/Pulperias/{id}', [PulperiaController::class, 'update']);
    Route::delete('/Pulperias/{id}', [PulperiaController::class, 'destroy']);

    // Clientes routes (lowercase)
    Route::apiResource('clientes', ClienteController::class);
    Route::get('clientes/{id}/cronogramas', [ClienteController::class, 'cronogramas']);
    Route::get('clientes/{id}/visitas', [ClienteController::class, 'visitas']);
    Route::get('clientes/{id}/pedidos', [ClienteController::class, 'pedidos']);

    // Clientes routes (capitalized - for Flutter compatibility)
    Route::get('/Clientes', [ClienteController::class, 'index']);
    Route::post('/Clientes', [ClienteController::class, 'store']);
    Route::get('/Clientes/{id}', [ClienteController::class, 'show']);
    Route::put('/Clientes/{id}', [ClienteController::class, 'update']);
    Route::delete('/Clientes/{id}', [ClienteController::class, 'destroy']);
    Route::get('/Clientes/{id}/cronogramas', [ClienteController::class, 'cronogramas']);
    Route::get('/Clientes/{id}/visitas', [ClienteController::class, 'visitas']);
    Route::get('/Clientes/{id}/pedidos', [ClienteController::class, 'pedidos']);

    // Pedidos routes (lowercase)
    Route::apiResource('pedidos', PedidoController::class);

    // Pedidos routes (capitalized - for Flutter compatibility)
    Route::get('/Pedidos', [PedidoController::class, 'index']);
    Route::post('/Pedidos', [PedidoController::class, 'store']);
    Route::get('/Pedidos/{id}', [PedidoController::class, 'show']);
    Route::put('/Pedidos/{id}', [PedidoController::class, 'update']);
    Route::delete('/Pedidos/{id}', [PedidoController::class, 'destroy']);

    // Usuarios routes (lowercase)
    Route::apiResource('usuarios', UserController::class);

    // Usuarios routes (capitalized - for Flutter compatibility)
    Route::get('/Usuarios', [UserController::class, 'index']);
    Route::post('/Usuarios', [UserController::class, 'store']);
    Route::get('/Usuarios/{id}', [UserController::class, 'show']);
    Route::put('/Usuarios/{id}', [UserController::class, 'update']);
    Route::delete('/Usuarios/{id}', [UserController::class, 'destroy']);

    // Cronograma Visitas routes (lowercase)
    Route::apiResource('cronograma-visitas', CronogramaVisitaController::class);

    // Cronograma Visitas routes (capitalized - for Flutter compatibility)
    Route::get('/CronogramaVisitas', [CronogramaVisitaController::class, 'index']);
    Route::post('/CronogramaVisitas', [CronogramaVisitaController::class, 'store']);
    Route::get('/CronogramaVisitas/{id}', [CronogramaVisitaController::class, 'show']);
    Route::put('/CronogramaVisitas/{id}', [CronogramaVisitaController::class, 'update']);
    Route::delete('/CronogramaVisitas/{id}', [CronogramaVisitaController::class, 'destroy']);

    // Visitas Clientes routes (lowercase)
    Route::apiResource('visitas-clientes', VisitaClienteController::class);

    // Visitas Clientes routes (capitalized - for Flutter compatibility)
    Route::get('/VisitasClientes', [VisitaClienteController::class, 'index']);
    Route::post('/VisitasClientes', [VisitaClienteController::class, 'store']);
    Route::get('/VisitasClientes/{id}', [VisitaClienteController::class, 'show']);
    Route::put('/VisitasClientes/{id}', [VisitaClienteController::class, 'update']);
    Route::delete('/VisitasClientes/{id}', [VisitaClienteController::class, 'destroy']);
});
