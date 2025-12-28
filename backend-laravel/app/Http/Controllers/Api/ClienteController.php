<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Cliente;
use Illuminate\Http\Request;

class ClienteController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        $query = Cliente::with('pulperia');

        // Filtrar por pulpería si se proporciona
        if ($request->has('pulperiaId')) {
            $query->where('pulperiaId', $request->pulperiaId);
        }

        $clientes = $query->orderBy('nombre', 'asc')
            ->get()
            ->map(function ($cliente) {
                return [
                    'id' => $cliente->id,
                    'nombre' => $cliente->nombre,
                    'direccion' => $cliente->direccion,
                    'telefono' => $cliente->telefono,
                    'pulperiaId' => $cliente->pulperiaId,
                    'nombrePulperia' => $cliente->nombrePulperia,
                    'created_at' => $cliente->created_at,
                    'updated_at' => $cliente->updated_at,
                ];
            });

        return response()->json([
            'data' => $clientes
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
            'pulperiaId' => 'nullable|exists:pulperias,id',
        ]);

        $cliente = Cliente::create([
            'nombre' => $request->nombre,
            'direccion' => $request->direccion,
            'telefono' => $request->telefono,
            'pulperiaId' => $request->pulperiaId,
        ]);

        // Load pulperia relationship
        $cliente->load('pulperia');

        return response()->json([
            'data' => [
                'id' => $cliente->id,
                'nombre' => $cliente->nombre,
                'direccion' => $cliente->direccion,
                'telefono' => $cliente->telefono,
                'pulperiaId' => $cliente->pulperiaId,
                'nombrePulperia' => $cliente->nombrePulperia,
                'created_at' => $cliente->created_at,
                'updated_at' => $cliente->updated_at,
            ]
        ], 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        $cliente = Cliente::with('pulperia')->findOrFail($id);

        return response()->json([
            'data' => [
                'id' => $cliente->id,
                'nombre' => $cliente->nombre,
                'direccion' => $cliente->direccion,
                'telefono' => $cliente->telefono,
                'pulperiaId' => $cliente->pulperiaId,
                'nombrePulperia' => $cliente->nombrePulperia,
                'created_at' => $cliente->created_at,
                'updated_at' => $cliente->updated_at,
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
            'pulperiaId' => 'nullable|exists:pulperias,id',
        ]);

        $cliente = Cliente::findOrFail($id);
        $cliente->update([
            'nombre' => $request->nombre,
            'direccion' => $request->direccion,
            'telefono' => $request->telefono,
            'pulperiaId' => $request->pulperiaId,
        ]);

        // Load pulperia relationship
        $cliente->load('pulperia');

        return response()->json([
            'data' => [
                'id' => $cliente->id,
                'nombre' => $cliente->nombre,
                'direccion' => $cliente->direccion,
                'telefono' => $cliente->telefono,
                'pulperiaId' => $cliente->pulperiaId,
                'nombrePulperia' => $cliente->nombrePulperia,
                'created_at' => $cliente->created_at,
                'updated_at' => $cliente->updated_at,
            ]
        ]);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        $cliente = Cliente::findOrFail($id);
        $cliente->delete();

        return response()->json([
            'message' => 'Cliente eliminado exitosamente'
        ]);
    }

    /**
     * Get cronogramas by cliente
     */
    public function cronogramas(string $id)
    {
        $cliente = Cliente::findOrFail($id);
        $cronogramas = $cliente->cronogramaVisitas()
            ->orderBy('orden', 'asc')
            ->get();

        return response()->json([
            'data' => $cronogramas
        ]);
    }

    /**
     * Get visitas by cliente
     */
    public function visitas(string $id)
    {
        $cliente = Cliente::findOrFail($id);
        $visitas = $cliente->visitas()
            ->orderBy('fecha', 'desc')
            ->get();

        return response()->json([
            'data' => $visitas
        ]);
    }

    /**
     * Get pedidos by cliente
     */
    public function pedidos(string $id)
    {
        $cliente = Cliente::findOrFail($id);
        $pedidos = $cliente->pedidos()
            ->with('detalles')
            ->orderBy('fecha', 'desc')
            ->get();

        return response()->json([
            'data' => $pedidos
        ]);
    }
}
