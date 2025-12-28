<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CronogramaVisita;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class CronogramaVisitaController extends Controller
{
    public function index(Request $request)
    {
        try {
            $query = CronogramaVisita::query();

            if ($request->has('clienteId')) {
                $query->where('clienteId', $request->clienteId);
            }

            $cronogramas = $query->orderBy('dia_semana')->get();

            return response()->json([
                'data' => $cronogramas->map(function ($cronograma) {
                    return $this->formatCronograma($cronograma);
                })
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Error al obtener cronogramas de visita',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    public function store(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'clienteId' => 'required|exists:clientes,id',
                'dia_semana' => 'required|string',
                'orden' => 'nullable|integer',
                'activo' => 'boolean'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'error' => 'Datos de validación incorrectos',
                    'messages' => $validator->errors()
                ], 422);
            }

            $cronograma = CronogramaVisita::create([
                'clienteId' => $request->clienteId,
                'dia_semana' => $request->dia_semana,
                'orden' => $request->orden,
                'activo' => $request->activo ?? true,
            ]);

            return response()->json([
                'data' => $this->formatCronograma($cronograma)
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Error al crear cronograma de visita',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    public function update(Request $request, $id)
    {
        try {
            $cronograma = CronogramaVisita::findOrFail($id);

            $validator = Validator::make($request->all(), [
                'dia_semana' => 'string',
                'orden' => 'nullable|integer',
                'activo' => 'boolean'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'error' => 'Datos de validación incorrectos',
                    'messages' => $validator->errors()
                ], 422);
            }

            $cronograma->update($request->only(['dia_semana', 'orden', 'activo']));

            return response()->json([
                'data' => $this->formatCronograma($cronograma)
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Error al actualizar cronograma de visita',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    public function destroy($id)
    {
        try {
            $cronograma = CronogramaVisita::findOrFail($id);
            $cronograma->delete();

            return response()->json([
                'message' => 'Cronograma de visita eliminado exitosamente'
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Error al eliminar cronograma de visita',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    private function formatCronograma($cronograma)
    {
        return [
            'id' => $cronograma->id,
            'clienteId' => $cronograma->clienteId,
            'dia_semana' => $cronograma->dia_semana,
            'orden' => $cronograma->orden,
            'activo' => $cronograma->activo,
        ];
    }
}
