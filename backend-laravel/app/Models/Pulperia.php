<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Pulperia extends Model
{
    use HasFactory, SoftDeletes;

    /**
     * The table associated with the model.
     *
     * @var string
     */
    protected $table = 'pulperias';

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'nombre',
        'direccion',
        'telefono',
        'rutaId',
        'orden',
        'cantidadClientes',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'rutaId' => 'integer',
            'orden' => 'integer',
            'cantidadClientes' => 'integer',
        ];
    }

    /**
     * Get the ruta that owns the pulperia.
     */
    public function ruta()
    {
        return $this->belongsTo(Ruta::class, 'rutaId');
    }

    /**
     * Get the nombre of the ruta
     */
    public function getNombreRutaAttribute()
    {
        return $this->ruta ? $this->ruta->nombre : null;
    }

    /**
     * Boot method to update ruta counts
     */
    protected static function booted()
    {
        static::saved(function ($pulperia) {
            if ($pulperia->ruta) {
                $pulperia->ruta->updateCounts();
            }
        });

        static::deleted(function ($pulperia) {
            if ($pulperia->ruta) {
                $pulperia->ruta->updateCounts();
            }
        });
    }
}
