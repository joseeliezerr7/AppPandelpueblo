<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Producto;
use Illuminate\Http\Request;

class ProductoController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $productos = Producto::with('categoria')->orderBy('nombre', 'asc')->get();

        return response()->json([
            'data' => $productos
        ]);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $request->validate([
            'nombre' => 'required|string|max:255',
            'precioCompra' => 'required|numeric|min:0',
            'precioVenta' => 'required|numeric|min:0',
            'cantidad' => 'required|integer|min:0',
            'categoriaId' => 'required|exists:categorias,id',
        ]);

        $producto = Producto::create([
            'nombre' => $request->nombre,
            'precioCompra' => $request->precioCompra,
            'precioVenta' => $request->precioVenta,
            'cantidad' => $request->cantidad,
            'categoriaId' => $request->categoriaId,
        ]);

        // Load categoria relationship
        $producto->load('categoria');

        return response()->json([
            'data' => $producto
        ], 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        $producto = Producto::with('categoria')->findOrFail($id);

        return response()->json([
            'data' => $producto
        ]);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        $request->validate([
            'nombre' => 'required|string|max:255',
            'precioCompra' => 'required|numeric|min:0',
            'precioVenta' => 'required|numeric|min:0',
            'cantidad' => 'required|integer|min:0',
            'categoriaId' => 'required|exists:categorias,id',
        ]);

        $producto = Producto::findOrFail($id);
        $producto->update([
            'nombre' => $request->nombre,
            'precioCompra' => $request->precioCompra,
            'precioVenta' => $request->precioVenta,
            'cantidad' => $request->cantidad,
            'categoriaId' => $request->categoriaId,
        ]);

        // Load categoria relationship
        $producto->load('categoria');

        return response()->json([
            'data' => $producto
        ]);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        $producto = Producto::findOrFail($id);
        $producto->delete();

        return response()->json([
            'message' => 'Producto eliminado exitosamente'
        ]);
    }

    /**
     * Update stock quantity
     */
    public function updateStock(Request $request, string $id)
    {
        $request->validate([
            'cantidad' => 'required|integer|min:0',
        ]);

        $producto = Producto::findOrFail($id);
        $producto->update([
            'cantidad' => $request->cantidad,
        ]);

        return response()->json([
            'data' => $producto
        ]);
    }
}
