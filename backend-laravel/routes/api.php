<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CategoriaController;
use App\Http\Controllers\Api\ProductoController;
use App\Http\Controllers\Api\RutaController;
use App\Http\Controllers\Api\PulperiaController;

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

    // Rutas routes (capitalized - for Flutter compatibility)
    Route::get('/Rutas', [RutaController::class, 'index']);
    Route::post('/Rutas', [RutaController::class, 'store']);
    Route::get('/Rutas/{id}', [RutaController::class, 'show']);
    Route::put('/Rutas/{id}', [RutaController::class, 'update']);
    Route::delete('/Rutas/{id}', [RutaController::class, 'destroy']);
    Route::get('/Rutas/{id}/pulperias', [RutaController::class, 'pulperias']);

    // Pulperias routes (lowercase)
    Route::apiResource('pulperias', PulperiaController::class);

    // Pulperias routes (capitalized - for Flutter compatibility)
    Route::get('/Pulperias', [PulperiaController::class, 'index']);
    Route::post('/Pulperias', [PulperiaController::class, 'store']);
    Route::get('/Pulperias/{id}', [PulperiaController::class, 'show']);
    Route::put('/Pulperias/{id}', [PulperiaController::class, 'update']);
    Route::delete('/Pulperias/{id}', [PulperiaController::class, 'destroy']);
});
