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
        Schema::create('cronograma_visitas', function (Blueprint $table) {
            $table->id();
            $table->foreignId('clienteId')->constrained('clientes')->onDelete('cascade');
            $table->string('dia_semana'); // lunes, martes, miércoles, etc.
            $table->integer('orden')->nullable();
            $table->boolean('activo')->default(true);
            $table->timestamps();
            $table->softDeletes();

            // Constraint: un cliente no puede tener el mismo día repetido
            $table->unique(['clienteId', 'dia_semana']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('cronograma_visitas');
    }
};
