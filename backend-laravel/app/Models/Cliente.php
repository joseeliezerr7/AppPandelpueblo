<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Cliente extends Model
{
    use HasFactory, SoftDeletes;

    /**
     * The table associated with the model.
     *
     * @var string
     */
    protected $table = 'clientes';

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'nombre',
        'direccion',
        'telefono',
        'pulperiaId',
        'latitude',
        'longitude',
        'usuarioId',
        'orden',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'pulperiaId' => 'integer',
            'usuarioId' => 'integer',
            'orden' => 'integer',
            'latitude' => 'decimal:7',
            'longitude' => 'decimal:7',
        ];
    }

    /**
     * Get the pulperia that owns the cliente.
     */
    public function pulperia()
    {
        return $this->belongsTo(Pulperia::class, 'pulperiaId');
    }

    /**
     * Get the usuario (encargado) that owns the cliente.
     */
    public function usuario()
    {
        return $this->belongsTo(User::class, 'usuarioId');
    }

    /**
     * Get the pedidos for the cliente.
     */
    public function pedidos()
    {
        return $this->hasMany(Pedido::class, 'clienteId');
    }

    /**
     * Get the cronograma de visitas for the cliente.
     */
    public function cronogramaVisitas()
    {
        return $this->hasMany(CronogramaVisita::class, 'clienteId');
    }

    /**
     * Get the visitas realizadas for the cliente.
     */
    public function visitas()
    {
        return $this->hasMany(VisitaCliente::class, 'clienteId');
    }

    /**
     * Get the nombre of the pulperia
     */
    public function getNombrePulperiaAttribute()
    {
        return $this->pulperia ? $this->pulperia->nombre : null;
    }

    /**
     * Boot method to update pulperia counts
     */
    protected static function booted()
    {
        static::saved(function ($cliente) {
            if ($cliente->pulperia) {
                $count = Cliente::where('pulperiaId', $cliente->pulperiaId)->count();
                $cliente->pulperia->update(['cantidadClientes' => $count]);
            }
        });

        static::deleted(function ($cliente) {
            if ($cliente->pulperia) {
                $count = Cliente::where('pulperiaId', $cliente->pulperiaId)->count();
                $cliente->pulperia->update(['cantidadClientes' => $count]);
            }
        });
    }
}
