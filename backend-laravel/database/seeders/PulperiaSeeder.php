<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Pulperia;
use App\Models\Ruta;

class PulperiaSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $rutas = Ruta::all();

        $pulperias = [
            ['nombre' => 'Pulpería El Buen Precio', 'direccion' => 'Barrio Central, 2c al Norte', 'telefono' => '+505 2222-1111'],
            ['nombre' => 'Pulpería La Esquina', 'direccion' => 'Barrio San José, frente al parque', 'telefono' => '+505 2222-2222'],
            ['nombre' => 'Pulpería Don Pedro', 'direccion' => 'Barrio El Carmen, casa #45', 'telefono' => '+505 2222-3333'],
            ['nombre' => 'Pulpería La Barata', 'direccion' => 'Barrio Monseñor Lezcano, 1c abajo', 'telefono' => '+505 2222-4444'],
            ['nombre' => 'Pulpería Mi Tiendita', 'direccion' => 'Barrio El Rosario, 3c al Este', 'telefono' => '+505 2222-5555'],
            ['nombre' => 'Pulpería Los Gemelos', 'direccion' => 'Barrio La Luz, del semáforo 2c al Sur', 'telefono' => '+505 2222-6666'],
            ['nombre' => 'Pulpería El Ahorro', 'direccion' => 'Barrio Santa Ana, frente a la iglesia', 'telefono' => '+505 2222-7777'],
            ['nombre' => 'Pulpería La Bendición', 'direccion' => 'Barrio San Sebastián, casa #78', 'telefono' => '+505 2222-8888'],
            ['nombre' => 'Pulpería El Progreso', 'direccion' => 'Barrio San Miguel, 1c arriba', 'telefono' => '+505 2222-9999'],
            ['nombre' => 'Pulpería La Providencia', 'direccion' => 'Barrio El Calvario, 2c al Oeste', 'telefono' => '+505 2222-0000'],
        ];

        foreach ($pulperias as $index => $data) {
            $ruta = $rutas->random();

            Pulperia::create([
                'nombre' => $data['nombre'],
                'direccion' => $data['direccion'],
                'telefono' => $data['telefono'],
                'rutaId' => $ruta->id,
                'orden' => $index + 1,
                'cantidadClientes' => rand(10, 50),
            ]);
        }
    }
}
