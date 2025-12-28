<?php

require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;

echo "=== Crear Usuario Admin ===\n\n";

$nombre = 'Admin';
$email = 'admin@pandelpueblo.com';
$password = 'admin123';
$telefono = '0000-0000';
$permiso = 'admin';

// Verificar si ya existe
$existente = DB::table('users')->where('correoElectronico', $email)->first();

if ($existente) {
    echo "Usuario ya existe. Actualizando contraseña...\n";
    DB::table('users')
        ->where('correoElectronico', $email)
        ->update([
            'password' => Hash::make($password),
            'updated_at' => now(),
        ]);
    echo "✓ Contraseña actualizada exitosamente\n\n";
} else {
    echo "Creando nuevo usuario admin...\n";
    DB::table('users')->insert([
        'nombre' => $nombre,
        'correoElectronico' => $email,
        'telefono' => $telefono,
        'password' => Hash::make($password),
        'permiso' => $permiso,
        'created_at' => now(),
        'updated_at' => now(),
    ]);
    echo "✓ Usuario creado exitosamente\n\n";
}

echo "Credenciales de acceso:\n";
echo "Email:    {$email}\n";
echo "Password: {$password}\n";
echo "\n¡Importante! Cambia esta contraseña después de iniciar sesión.\n";
