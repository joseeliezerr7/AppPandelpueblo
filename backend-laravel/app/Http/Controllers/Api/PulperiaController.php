<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Pulperia;
use Illuminate\Http\Request;

class PulperiaController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $pulperias = Pulperia::with('ruta')
            ->orderBy('rutaId', 'asc')
            ->orderBy('orden', 'asc')
            ->get()
            ->map(function ($pulperia) {
                return [
                    'id' => $pulperia->id,
                    'nombre' => $pulperia->nombre,
                    'direccion' => $pulperia->direccion,
                    'telefono' => $pulperia->telefono,
                    'rutaId' => $pulperia->rutaId,
                    'nombreRuta' => $pulperia->nombreRuta,
                    'orden' => $pulperia->orden,
                    'cantidadClientes' => $pulperia->cantidadClientes,
                    'created_at' => $pulperia->created_at,
                    'updated_at' => $pulperia->updated_at,
                ];
            });

        return response()->json([
            'data' => $pulperias
        ]);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $request->validate([
            'nombre' => 'required|string|max:255',
            'direccion' => 'required|string|max:255',
            'telefono' => 'required|string|max:20',
            'rutaId' => 'nullable|exists:rutas,id',
            'orden' => 'nullable|integer|min:0',
            'cantidadClientes' => 'nullable|integer|min:0',
        ]);

        $pulperia = Pulperia::create([
            'nombre' => $request->nombre,
            'direccion' => $request->direccion,
            'telefono' => $request->telefono,
            'rutaId' => $request->rutaId,
            'orden' => $request->orden ?? 0,
            'cantidadClientes' => $request->cantidadClientes ?? 0,
        ]);

        // Load ruta relationship
        $pulperia->load('ruta');

        return response()->json([
            'data' => [
                'id' => $pulperia->id,
                'nombre' => $pulperia->nombre,
                'direccion' => $pulperia->direccion,
                'telefono' => $pulperia->telefono,
                'rutaId' => $pulperia->rutaId,
                'nombreRuta' => $pulperia->nombreRuta,
                'orden' => $pulperia->orden,
                'cantidadClientes' => $pulperia->cantidadClientes,
                'created_at' => $pulperia->created_at,
                'updated_at' => $pulperia->updated_at,
            ]
        ], 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        $pulperia = Pulperia::with('ruta')->findOrFail($id);

        return response()->json([
            'data' => [
                'id' => $pulperia->id,
                'nombre' => $pulperia->nombre,
                'direccion' => $pulperia->direccion,
                'telefono' => $pulperia->telefono,
                'rutaId' => $pulperia->rutaId,
                'nombreRuta' => $pulperia->nombreRuta,
                'orden' => $pulperia->orden,
                'cantidadClientes' => $pulperia->cantidadClientes,
                'created_at' => $pulperia->created_at,
                'updated_at' => $pulperia->updated_at,
            ]
        ]);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        $request->validate([
            'nombre' => 'required|string|max:255',
            'direccion' => 'required|string|max:255',
            'telefono' => 'required|string|max:20',
            'rutaId' => 'nullable|exists:rutas,id',
            'orden' => 'nullable|integer|min:0',
            'cantidadClientes' => 'nullable|integer|min:0',
        ]);

        $pulperia = Pulperia::findOrFail($id);
        $pulperia->update([
            'nombre' => $request->nombre,
            'direccion' => $request->direccion,
            'telefono' => $request->telefono,
            'rutaId' => $request->rutaId,
            'orden' => $request->orden ?? $pulperia->orden,
            'cantidadClientes' => $request->cantidadClientes ?? $pulperia->cantidadClientes,
        ]);

        // Load ruta relationship
        $pulperia->load('ruta');

        return response()->json([
            'data' => [
                'id' => $pulperia->id,
                'nombre' => $pulperia->nombre,
                'direccion' => $pulperia->direccion,
                'telefono' => $pulperia->telefono,
                'rutaId' => $pulperia->rutaId,
                'nombreRuta' => $pulperia->nombreRuta,
                'orden' => $pulperia->orden,
                'cantidadClientes' => $pulperia->cantidadClientes,
                'created_at' => $pulperia->created_at,
                'updated_at' => $pulperia->updated_at,
            ]
        ]);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        $pulperia = Pulperia::findOrFail($id);
        $pulperia->delete();

        return response()->json([
            'message' => 'Pulpería eliminada exitosamente'
        ]);
    }
}
