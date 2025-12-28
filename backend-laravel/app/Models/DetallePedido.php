<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class DetallePedido extends Model
{
    use HasFactory, SoftDeletes;

    /**
     * The table associated with the model.
     *
     * @var string
     */
    protected $table = 'detalles_pedido';

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'pedidoId',
        'productoId',
        'cantidad',
        'precio',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'pedidoId' => 'integer',
            'productoId' => 'integer',
            'cantidad' => 'integer',
            'precio' => 'decimal:2',
        ];
    }

    /**
     * Get the pedido that owns the detalle.
     */
    public function pedido()
    {
        return $this->belongsTo(Pedido::class, 'pedidoId');
    }

    /**
     * Get the producto that owns the detalle.
     */
    public function producto()
    {
        return $this->belongsTo(Producto::class, 'productoId');
    }

    /**
     * Get the nombre of the producto
     */
    public function getNombreProductoAttribute()
    {
        return $this->producto ? $this->producto->nombre : null;
    }

    /**
     * Boot method to update pedido total
     */
    protected static function booted()
    {
        static::saved(function ($detalle) {
            if ($detalle->pedido) {
                $detalle->pedido->calcularTotal();
            }
        });

        static::deleted(function ($detalle) {
            if ($detalle->pedido) {
                $detalle->pedido->calcularTotal();
            }
        });
    }
}
