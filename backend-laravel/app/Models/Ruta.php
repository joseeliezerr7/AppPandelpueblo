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
        'cantidadPulperias',
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
            'cantidadPulperias' => 'integer',
            'cantidadClientes' => 'integer',
        ];
    }

    /**
     * Get the pulperias for the ruta.
     */
    public function pulperias()
    {
        return $this->hasMany(Pulperia::class, 'rutaId');
    }

    /**
     * Update pulperias and clientes count
     */
    public function updateCounts()
    {
        $this->cantidadPulperias = $this->pulperias()->count();
        $this->cantidadClientes = $this->pulperias()->sum('cantidadClientes');
        $this->save();
    }
}
