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
        Schema::create('visitas_clientes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('clienteId')->constrained('clientes')->onDelete('cascade');
            $table->dateTime('fecha');
            $table->boolean('realizada')->default(false);
            $table->text('notas')->nullable();
            $table->timestamps();
            $table->softDeletes();

            // Índice para búsquedas rápidas por cliente y fecha
            $table->index(['clienteId', 'fecha']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('visitas_clientes');
    }
};
