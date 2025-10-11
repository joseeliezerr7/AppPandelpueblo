<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use App\Models\User;

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Admin user
        User::create([
            'nombre' => 'Administrador',
            'correoElectronico' => 'admin@pandelpueblo.com',
            'telefono' => '+505 8888-8888',
            'password' => Hash::make('admin123'),
            'permiso' => 'admin',
        ]);

        // Vendedor user
        User::create([
            'nombre' => 'Vendedor Demo',
            'correoElectronico' => 'vendedor@pandelpueblo.com',
            'telefono' => '+505 7777-7777',
            'password' => Hash::make('vendedor123'),
            'permiso' => 'vendedor',
        ]);

        // Usuario regular
        User::create([
            'nombre' => 'Usuario Demo',
            'correoElectronico' => 'usuario@pandelpueblo.com',
            'telefono' => '+505 6666-6666',
            'password' => Hash::make('usuario123'),
            'permiso' => 'usuario',
        ]);
    }
}
