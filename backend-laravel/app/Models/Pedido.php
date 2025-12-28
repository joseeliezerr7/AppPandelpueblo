<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Pedido extends Model
{
    use HasFactory, SoftDeletes;

    /**
     * The table associated with the model.
     *
     * @var string
     */
    protected $table = 'pedidos';

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'clienteId',
        'pulperiaId',
        'fecha',
        'total',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'clienteId' => 'integer',
            'pulperiaId' => 'integer',
            'fecha' => 'datetime',
            'total' => 'decimal:2',
        ];
    }

    /**
     * Get the cliente that owns the pedido.
     */
    public function cliente()
    {
        return $this->belongsTo(Cliente::class, 'clienteId');
    }

    /**
     * Get the pulperia that owns the pedido.
     */
    public function pulperia()
    {
        return $this->belongsTo(Pulperia::class, 'pulperiaId');
    }

    /**
     * Get the detalles for the pedido.
     */
    public function detalles()
    {
        return $this->hasMany(DetallePedido::class, 'pedidoId');
    }

    /**
     * Get the nombre of the cliente
     */
    public function getNombreClienteAttribute()
    {
        return $this->cliente ? $this->cliente->nombre : null;
    }

    /**
     * Get the nombre of the pulperia
     */
    public function getNombrePulperiaAttribute()
    {
        return $this->pulperia ? $this->pulperia->nombre : null;
    }

    /**
     * Calculate total from detalles
     */
    public function calcularTotal()
    {
        $total = $this->detalles()->sum(\DB::raw('cantidad * precio'));
        // Usar updateQuietly para evitar disparar eventos y crear loop infinito
        $this->updateQuietly(['total' => $total]);
    }
}
