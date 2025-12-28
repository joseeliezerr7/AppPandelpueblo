<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('pedidos', function (Blueprint $table) {
            // Eliminar las restricciones de FOREIGN KEY
            $table->dropForeign(['clienteId']);
            $table->dropForeign(['pulperiaId']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('pedidos', function (Blueprint $table) {
            // Restaurar las restricciones
            $table->foreign('clienteId')->references('id')->on('clientes')->onDelete('cascade');
            $table->foreign('pulperiaId')->references('id')->on('pulperias')->onDelete('set null');
        });
    }
};
