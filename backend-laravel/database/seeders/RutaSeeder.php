<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Ruta;

class RutaSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $rutas = [
            'Ruta Centro',
            'Ruta Norte',
            'Ruta Sur',
            'Ruta Este',
            'Ruta Oeste',
        ];

        foreach ($rutas as $nombre) {
            Ruta::create([
                'nombre' => $nombre,
                'cantidadPulperias' => 0,
                'cantidadClientes' => 0,
            ]);
        }
    }
}
