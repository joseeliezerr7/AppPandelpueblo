<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class UserController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $users = User::orderBy('nombre', 'asc')
            ->get()
            ->map(function ($user) {
                return [
                    'id' => $user->id,
                    'nombre' => $user->nombre,
                    'correoElectronico' => $user->correoElectronico,
                    'telefono' => $user->telefono,
                    'permiso' => $user->permiso,
                    'created_at' => $user->created_at,
                    'updated_at' => $user->updated_at,
                ];
            });

        return response()->json([
            'data' => $users
        ]);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $request->validate([
            'nombre' => 'required|string|max:255',
            'correoElectronico' => 'required|email|unique:users,correoElectronico|max:255',
            'telefono' => 'nullable|string|max:20',
            'password' => 'required|string|min:6',
            'permiso' => 'required|string|in:admin,empleado,vendedor',
        ]);

        $user = User::create([
            'nombre' => $request->nombre,
            'correoElectronico' => $request->correoElectronico,
            'telefono' => $request->telefono,
            'password' => Hash::make($request->password),
            'permiso' => $request->permiso,
        ]);

        return response()->json([
            'data' => [
                'id' => $user->id,
                'nombre' => $user->nombre,
                'correoElectronico' => $user->correoElectronico,
                'telefono' => $user->telefono,
                'permiso' => $user->permiso,
                'created_at' => $user->created_at,
                'updated_at' => $user->updated_at,
            ]
        ], 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        $user = User::findOrFail($id);

        return response()->json([
            'data' => [
                'id' => $user->id,
                'nombre' => $user->nombre,
                'correoElectronico' => $user->correoElectronico,
                'telefono' => $user->telefono,
                'permiso' => $user->permiso,
                'created_at' => $user->created_at,
                'updated_at' => $user->updated_at,
            ]
        ]);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        $user = User::findOrFail($id);

        $request->validate([
            'nombre' => 'required|string|max:255',
            'correoElectronico' => [
                'required',
                'email',
                'max:255',
                Rule::unique('users', 'correoElectronico')->ignore($user->id),
            ],
            'telefono' => 'nullable|string|max:20',
            'password' => 'nullable|string|min:6',
            'permiso' => 'required|string|in:admin,empleado,vendedor',
        ]);

        $updateData = [
            'nombre' => $request->nombre,
            'correoElectronico' => $request->correoElectronico,
            'telefono' => $request->telefono,
            'permiso' => $request->permiso,
        ];

        // Solo actualizar password si se proporciona
        if ($request->filled('password')) {
            $updateData['password'] = Hash::make($request->password);
        }

        $user->update($updateData);

        return response()->json([
            'data' => [
                'id' => $user->id,
                'nombre' => $user->nombre,
                'correoElectronico' => $user->correoElectronico,
                'telefono' => $user->telefono,
                'permiso' => $user->permiso,
                'created_at' => $user->created_at,
                'updated_at' => $user->updated_at,
            ]
        ]);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        $user = User::findOrFail($id);

        // Prevenir que el usuario se elimine a sí mismo
        if ($user->id === auth()->id()) {
            return response()->json([
                'message' => 'No puedes eliminar tu propio usuario'
            ], 403);
        }

        $user->delete();

        return response()->json([
            'message' => 'Usuario eliminado exitosamente'
        ]);
    }
}
