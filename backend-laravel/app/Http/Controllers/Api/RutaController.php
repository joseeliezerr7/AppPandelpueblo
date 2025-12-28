<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Ruta;
use Illuminate\Http\Request;

class RutaController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $rutas = Ruta::withCount(['pulperias', 'clientes'])
            ->orderBy('nombre', 'asc')
            ->get();

        return response()->json([
            'data' => $rutas
        ]);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $request->validate([
            'nombre' => 'required|string|max:255',
        ]);

        $ruta = Ruta::create([
            'nombre' => $request->nombre,
        ]);

        return response()->json([
            'data' => $ruta
        ], 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        $ruta = Ruta::with('pulperias')
            ->withCount(['pulperias', 'clientes'])
            ->findOrFail($id);

        return response()->json([
            'data' => $ruta
        ]);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        $request->validate([
            'nombre' => 'required|string|max:255',
        ]);

        $ruta = Ruta::findOrFail($id);
        $ruta->update([
            'nombre' => $request->nombre,
        ]);

        return response()->json([
            'data' => $ruta
        ]);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        $ruta = Ruta::findOrFail($id);
        $ruta->delete();

        return response()->json([
            'message' => 'Ruta eliminada exitosamente'
        ]);
    }

    /**
     * Get pulperias by ruta
     */
    public function pulperias(string $id)
    {
        $ruta = Ruta::findOrFail($id);
        $pulperias = $ruta->pulperias()->orderBy('orden', 'asc')->get();

        return response()->json([
            'data' => $pulperias
        ]);
    }

    /**
     * Get clientes by ruta
     */
    public function clientes(string $id)
    {
        $ruta = Ruta::findOrFail($id);
        $clientes = $ruta->clientes()
            ->with('pulperia')
            ->orderBy('orden', 'asc')
            ->get()
            ->map(function ($cliente) {
                return [
                    'id' => $cliente->id,
                    'nombre' => $cliente->nombre,
                    'direccion' => $cliente->direccion,
                    'telefono' => $cliente->telefono,
                    'pulperiaId' => $cliente->pulperiaId,
                    'nombrePulperia' => $cliente->pulperia ? $cliente->pulperia->nombre : null,
                    'latitude' => $cliente->latitude ? (float) $cliente->latitude : null,
                    'longitude' => $cliente->longitude ? (float) $cliente->longitude : null,
                    'usuarioId' => $cliente->usuarioId,
                    'orden' => $cliente->orden,
                ];
            });

        return response()->json([
            'data' => $clientes
        ]);
    }
}
