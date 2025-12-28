<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Pedido;
use App\Models\DetallePedido;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PedidoController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        $query = Pedido::with(['cliente', 'pulperia', 'detalles.producto']);

        // Filtrar por cliente si se proporciona
        if ($request->has('clienteId')) {
            $query->where('clienteId', $request->clienteId);
        }

        // Filtrar por pulpería si se proporciona
        if ($request->has('pulperiaId')) {
            $query->where('pulperiaId', $request->pulperiaId);
        }

        $pedidos = $query->orderBy('fecha', 'desc')
            ->get()
            ->map(function ($pedido) {
                return $this->formatPedido($pedido);
            });

        return response()->json([
            'data' => $pedidos
        ]);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        \Log::info('=== INICIO CREAR PEDIDO ===');
        \Log::info('Request data:', $request->all());

        $request->validate([
            'clienteId' => 'required|integer',
            'pulperiaId' => 'nullable|integer',
            'fecha' => 'required|date',
            'detalles' => 'required|array|min:1',
            'detalles.*.productoId' => 'required|integer',
            'detalles.*.cantidad' => 'required|integer|min:1',
            'detalles.*.precio' => 'required|numeric|min:0',
        ]);

        \Log::info('Validación completada');

        DB::beginTransaction();
        try {
            // Crear el pedido
            \Log::info('Creando pedido...');
            $pedido = Pedido::create([
                'clienteId' => $request->clienteId,
                'pulperiaId' => $request->pulperiaId,
                'fecha' => $request->fecha,
                'total' => 0,
            ]);
            \Log::info("Pedido creado con ID: {$pedido->id}");

            // Crear los detalles
            \Log::info('Creando detalles...');
            foreach ($request->detalles as $detalle) {
                DetallePedido::create([
                    'pedidoId' => $pedido->id,
                    'productoId' => $detalle['productoId'],
                    'cantidad' => $detalle['cantidad'],
                    'precio' => $detalle['precio'],
                ]);
            }
            \Log::info('Detalles creados');

            // Calcular total
            \Log::info('Calculando total...');
            $pedido->calcularTotal();
            \Log::info("Total calculado: {$pedido->total}");

            // Cargar relaciones (solo las que existan)
            \Log::info('Cargando relaciones...');
            $pedido->load(['detalles.producto']);

            // Intentar cargar cliente y pulperia si existen
            try {
                $pedido->load(['cliente', 'pulperia']);
            } catch (\Exception $e) {
                \Log::info('Cliente/Pulperia no encontrados (esperado)');
            }
            \Log::info('Relaciones cargadas');

            DB::commit();
            \Log::info('Transacción confirmada');

            $response = [
                'data' => $this->formatPedido($pedido)
            ];
            \Log::info('=== FIN CREAR PEDIDO EXITOSO ===');

            return response()->json($response, 201);
        } catch (\Exception $e) {
            DB::rollBack();
            \Log::error('Error al crear pedido: ' . $e->getMessage());
            \Log::error($e->getTraceAsString());
            return response()->json([
                'message' => 'Error al crear el pedido: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        $pedido = Pedido::with(['cliente', 'pulperia', 'detalles.producto'])->findOrFail($id);

        return response()->json([
            'data' => $this->formatPedido($pedido)
        ]);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        $request->validate([
            'clienteId' => 'required|integer',
            'pulperiaId' => 'nullable|integer',
            'fecha' => 'required|date',
            'detalles' => 'required|array|min:1',
            'detalles.*.id' => 'nullable|integer',
            'detalles.*.productoId' => 'required|integer',
            'detalles.*.cantidad' => 'required|integer|min:1',
            'detalles.*.precio' => 'required|numeric|min:0',
        ]);

        DB::beginTransaction();
        try {
            $pedido = Pedido::findOrFail($id);

            // Actualizar el pedido
            $pedido->update([
                'clienteId' => $request->clienteId,
                'pulperiaId' => $request->pulperiaId,
                'fecha' => $request->fecha,
            ]);

            // Obtener IDs de detalles existentes en la petición
            $detallesIds = collect($request->detalles)
                ->filter(fn($d) => isset($d['id']))
                ->pluck('id')
                ->toArray();

            // Eliminar detalles que no están en la petición
            DetallePedido::where('pedidoId', $pedido->id)
                ->whereNotIn('id', $detallesIds)
                ->delete();

            // Actualizar o crear detalles
            foreach ($request->detalles as $detalleData) {
                if (isset($detalleData['id'])) {
                    // Actualizar detalle existente
                    $detalle = DetallePedido::find($detalleData['id']);
                    if ($detalle && $detalle->pedidoId == $pedido->id) {
                        $detalle->update([
                            'productoId' => $detalleData['productoId'],
                            'cantidad' => $detalleData['cantidad'],
                            'precio' => $detalleData['precio'],
                        ]);
                    }
                } else {
                    // Crear nuevo detalle
                    DetallePedido::create([
                        'pedidoId' => $pedido->id,
                        'productoId' => $detalleData['productoId'],
                        'cantidad' => $detalleData['cantidad'],
                        'precio' => $detalleData['precio'],
                    ]);
                }
            }

            // Calcular total
            $pedido->calcularTotal();

            // Cargar relaciones
            $pedido->load(['cliente', 'pulperia', 'detalles.producto']);

            DB::commit();

            return response()->json([
                'data' => $this->formatPedido($pedido)
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'message' => 'Error al actualizar el pedido: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        DB::beginTransaction();
        try {
            $pedido = Pedido::findOrFail($id);

            // Eliminar detalles primero (aunque cascade lo haría)
            $pedido->detalles()->delete();

            // Eliminar pedido
            $pedido->delete();

            DB::commit();

            return response()->json([
                'message' => 'Pedido eliminado exitosamente'
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'message' => 'Error al eliminar el pedido: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Format pedido for response
     */
    private function formatPedido($pedido)
    {
        return [
            'id' => $pedido->id,
            'clienteId' => $pedido->clienteId,
            'nombreCliente' => $pedido->nombreCliente,
            'pulperiaId' => $pedido->pulperiaId,
            'nombrePulperia' => $pedido->nombrePulperia,
            'fecha' => $pedido->fecha->format('Y-m-d H:i:s'),
            'total' => (float) $pedido->total,
            'detalles' => $pedido->detalles->map(function ($detalle) {
                return [
                    'id' => $detalle->id,
                    'pedidoId' => $detalle->pedidoId,
                    'productoId' => $detalle->productoId,
                    'nombreProducto' => $detalle->nombreProducto,
                    'cantidad' => $detalle->cantidad,
                    'precio' => (float) $detalle->precio,
                    'created_at' => $detalle->created_at,
                    'updated_at' => $detalle->updated_at,
                ];
            }),
            'created_at' => $pedido->created_at,
            'updated_at' => $pedido->updated_at,
        ];
    }
}
