<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Producto;
use App\Models\Categoria;

class ProductoSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $categorias = Categoria::all();

        $productos = [
            // Panadería
            ['nombre' => 'Pan Francés', 'precioCompra' => 1.50, 'precioVenta' => 2.00, 'cantidad' => 100, 'categoria' => 'Panadería'],
            ['nombre' => 'Pan Integral', 'precioCompra' => 2.00, 'precioVenta' => 2.50, 'cantidad' => 50, 'categoria' => 'Panadería'],
            ['nombre' => 'Semita', 'precioCompra' => 3.00, 'precioVenta' => 4.00, 'cantidad' => 30, 'categoria' => 'Panadería'],

            // Bebidas
            ['nombre' => 'Coca Cola 2L', 'precioCompra' => 35.00, 'precioVenta' => 45.00, 'cantidad' => 24, 'categoria' => 'Bebidas'],
            ['nombre' => 'Pepsi 2L', 'precioCompra' => 33.00, 'precioVenta' => 43.00, 'cantidad' => 24, 'categoria' => 'Bebidas'],
            ['nombre' => 'Agua Embotellada 500ml', 'precioCompra' => 8.00, 'precioVenta' => 12.00, 'cantidad' => 48, 'categoria' => 'Bebidas'],
            ['nombre' => 'Jugo Naranja 1L', 'precioCompra' => 25.00, 'precioVenta' => 35.00, 'cantidad' => 20, 'categoria' => 'Bebidas'],

            // Lácteos
            ['nombre' => 'Leche Entera 1L', 'precioCompra' => 30.00, 'precioVenta' => 40.00, 'cantidad' => 30, 'categoria' => 'Lácteos'],
            ['nombre' => 'Queso Artesanal 1lb', 'precioCompra' => 60.00, 'precioVenta' => 80.00, 'cantidad' => 15, 'categoria' => 'Lácteos'],
            ['nombre' => 'Crema Ácida 250ml', 'precioCompra' => 20.00, 'precioVenta' => 28.00, 'cantidad' => 20, 'categoria' => 'Lácteos'],

            // Snacks
            ['nombre' => 'Papas Fritas Grande', 'precioCompra' => 18.00, 'precioVenta' => 25.00, 'cantidad' => 40, 'categoria' => 'Snacks'],
            ['nombre' => 'Galletas María', 'precioCompra' => 12.00, 'precioVenta' => 18.00, 'cantidad' => 35, 'categoria' => 'Snacks'],
            ['nombre' => 'Nachos 200g', 'precioCompra' => 20.00, 'precioVenta' => 28.00, 'cantidad' => 25, 'categoria' => 'Snacks'],

            // Granos Básicos
            ['nombre' => 'Arroz 1lb', 'precioCompra' => 12.00, 'precioVenta' => 16.00, 'cantidad' => 100, 'categoria' => 'Granos Básicos'],
            ['nombre' => 'Frijoles Rojos 1lb', 'precioCompra' => 15.00, 'precioVenta' => 20.00, 'cantidad' => 80, 'categoria' => 'Granos Básicos'],
            ['nombre' => 'Azúcar 1lb', 'precioCompra' => 10.00, 'precioVenta' => 14.00, 'cantidad' => 60, 'categoria' => 'Granos Básicos'],

            // Enlatados
            ['nombre' => 'Atún en Aceite', 'precioCompra' => 15.00, 'precioVenta' => 22.00, 'cantidad' => 50, 'categoria' => 'Enlatados'],
            ['nombre' => 'Sardinas', 'precioCompra' => 12.00, 'precioVenta' => 18.00, 'cantidad' => 40, 'categoria' => 'Enlatados'],
            ['nombre' => 'Salsa de Tomate', 'precioCompra' => 10.00, 'precioVenta' => 15.00, 'cantidad' => 35, 'categoria' => 'Enlatados'],

            // Limpieza
            ['nombre' => 'Detergente en Polvo 500g', 'precioCompra' => 25.00, 'precioVenta' => 35.00, 'cantidad' => 30, 'categoria' => 'Limpieza'],
            ['nombre' => 'Cloro 1L', 'precioCompra' => 15.00, 'precioVenta' => 22.00, 'cantidad' => 25, 'categoria' => 'Limpieza'],
            ['nombre' => 'Jabón de Platos', 'precioCompra' => 18.00, 'precioVenta' => 25.00, 'cantidad' => 20, 'categoria' => 'Limpieza'],
        ];

        foreach ($productos as $data) {
            $categoria = $categorias->firstWhere('nombre', $data['categoria']);

            if ($categoria) {
                Producto::create([
                    'nombre' => $data['nombre'],
                    'precioCompra' => $data['precioCompra'],
                    'precioVenta' => $data['precioVenta'],
                    'cantidad' => $data['cantidad'],
                    'categoriaId' => $categoria->id,
                ]);
            }
        }
    }
}
