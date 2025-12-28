<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class VisitaCliente extends Model
{
    use HasFactory, SoftDeletes;

    protected $table = 'visitas_clientes';

    protected $fillable = [
        'clienteId',
        'fecha',
        'realizada',
        'notas',
    ];

    protected $casts = [
        'realizada' => 'boolean',
        'fecha' => 'datetime',
    ];

    public function cliente()
    {
        return $this->belongsTo(Cliente::class, 'clienteId');
    }
}
