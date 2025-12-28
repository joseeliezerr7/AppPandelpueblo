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
        Schema::table('detalles_pedido', function (Blueprint $table) {
            // Eliminar la restricción de FOREIGN KEY de productoId
            // La de pedidoId la dejamos porque el pedido se crea antes
            $table->dropForeign(['productoId']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('detalles_pedido', function (Blueprint $table) {
            // Restaurar la restricción
            $table->foreign('productoId')->references('id')->on('productos')->onDelete('cascade');
        });
    }
};
