<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\VisitaCliente;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class VisitaClienteController extends Controller
{
    public function index(Request $request)
    {
        try {
            $query = VisitaCliente::query();

            if ($request->has('clienteId')) {
                $query->where('clienteId', $request->clienteId);
            }

            if ($request->has('fecha_desde')) {
                $query->where('fecha', '>=', $request->fecha_desde);
            }

            if ($request->has('fecha_hasta')) {
                $query->where('fecha', '<=', $request->fecha_hasta);
            }

            $visitas = $query->orderBy('fecha', 'desc')->get();

            return response()->json([
                'data' => $visitas->map(function ($visita) {
                    return $this->formatVisita($visita);
                })
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Error al obtener visitas de clientes',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    public function store(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'clienteId' => 'required|exists:clientes,id',
                'fecha' => 'required|date',
                'realizada' => 'boolean',
                'notas' => 'nullable|string'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'error' => 'Datos de validación incorrectos',
                    'messages' => $validator->errors()
                ], 422);
            }

            $visita = VisitaCliente::create([
                'clienteId' => $request->clienteId,
                'fecha' => $request->fecha,
                'realizada' => $request->realizada ?? false,
                'notas' => $request->notas,
            ]);

            return response()->json([
                'data' => $this->formatVisita($visita)
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Error al crear visita de cliente',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    public function update(Request $request, $id)
    {
        try {
            $visita = VisitaCliente::findOrFail($id);

            $validator = Validator::make($request->all(), [
                'fecha' => 'date',
                'realizada' => 'boolean',
                'notas' => 'nullable|string'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'error' => 'Datos de validación incorrectos',
                    'messages' => $validator->errors()
                ], 422);
            }

            $visita->update($request->only(['fecha', 'realizada', 'notas']));

            return response()->json([
                'data' => $this->formatVisita($visita)
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Error al actualizar visita de cliente',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    public function destroy($id)
    {
        try {
            $visita = VisitaCliente::findOrFail($id);
            $visita->delete();

            return response()->json([
                'message' => 'Visita de cliente eliminada exitosamente'
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Error al eliminar visita de cliente',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    private function formatVisita($visita)
    {
        return [
            'id' => $visita->id,
            'clienteId' => $visita->clienteId,
            'fecha' => $visita->fecha,
            'realizada' => $visita->realizada,
            'notas' => $visita->notas,
        ];
    }
}
