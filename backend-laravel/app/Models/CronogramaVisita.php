<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class CronogramaVisita extends Model
{
    use HasFactory, SoftDeletes;

    protected $table = 'cronograma_visitas';

    protected $fillable = [
        'clienteId',
        'dia_semana',
        'orden',
        'activo',
    ];

    protected $casts = [
        'activo' => 'boolean',
        'orden' => 'integer',
    ];

    public function cliente()
    {
        return $this->belongsTo(Cliente::class, 'clienteId');
    }
}
