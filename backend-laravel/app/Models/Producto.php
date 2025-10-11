<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Producto extends Model
{
    use HasFactory, SoftDeletes;

    /**
     * The table associated with the model.
     *
     * @var string
     */
    protected $table = 'productos';

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'nombre',
        'precioCompra',
        'precioVenta',
        'cantidad',
        'categoriaId',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'precioCompra' => 'decimal:2',
            'precioVenta' => 'decimal:2',
            'cantidad' => 'integer',
            'categoriaId' => 'integer',
        ];
    }

    /**
     * Get the categoria that owns the producto.
     */
    public function categoria()
    {
        return $this->belongsTo(Categoria::class, 'categoriaId');
    }
}
