<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Categoria;

class CategoriaSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $categorias = [
            'Panadería',
            'Bebidas',
            'Lácteos',
            'Snacks',
            'Granos Básicos',
            'Enlatados',
            'Limpieza',
            'Higiene Personal',
            'Dulces',
            'Condimentos',
        ];

        foreach ($categorias as $nombre) {
            Categoria::create([
                'nombre' => $nombre,
            ]);
        }
    }
}
