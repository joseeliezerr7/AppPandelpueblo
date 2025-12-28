<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Ruta extends Model
{
    use HasFactory, SoftDeletes;

    /**
     * The table associated with the model.
     *
     * @var string
     */
    protected $table = 'rutas';

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'nombre',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'cantidadPulperias' => 'integer',
            'cantidadClientes' => 'integer',
        ];
    }

    /**
     * Append computed attributes
     */
    protected $appends = ['cantidadPulperias', 'cantidadClientes'];

    /**
     * Get the usuarios (encargados) for this ruta.
     */
    public function usuarios()
    {
        return $this->hasMany(User::class, 'rutaId');
    }

    /**
     * Get the pulperias for this ruta.
     * Las pulperías son los clientes.
     */
    public function pulperias()
    {
        return $this->hasMany(Pulperia::class, 'rutaId');
    }

    /**
     * Get all clientes through pulperias.
     */
    public function clientes()
    {
        return $this->hasManyThrough(Cliente::class, Pulperia::class, 'rutaId', 'pulperiaId', 'id', 'id');
    }

    /**
     * Get cantidad de pulperias
     */
    public function getCantidadPulperiasAttribute()
    {
        // Si existe pulperias_count (generado por withCount), usarlo
        if (isset($this->attributes['pulperias_count'])) {
            return $this->attributes['pulperias_count'];
        }
        // Si no, hacer el conteo directo
        return $this->pulperias()->count();
    }

    /**
     * Get cantidad de clientes
     */
    public function getCantidadClientesAttribute()
    {
        // Si existe clientes_count (generado por withCount), usarlo
        if (isset($this->attributes['clientes_count'])) {
            return $this->attributes['clientes_count'];
        }
        // Si no, hacer el conteo directo
        return $this->clientes()->count();
    }

    /**
     * Update counts method (called from Pulperia model)
     */
    public function updateCounts()
    {
        $this->save();
    }
}
