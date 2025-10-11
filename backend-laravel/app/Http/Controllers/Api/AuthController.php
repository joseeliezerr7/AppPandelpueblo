<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    /**
     * Login user and create token
     */
    public function login(Request $request)
    {
        // Soportar tanto 'password' como 'contrasena'
        $password = $request->input('password') ?? $request->input('contrasena');

        $request->merge(['password' => $password]);

        $request->validate([
            'correoElectronico' => 'required|email',
            'password' => 'required',
        ]);

        $user = User::where('correoElectronico', $request->correoElectronico)->first();

        if (!$user || !Hash::check($password, $user->password)) {
            throw ValidationException::withMessages([
                'correoElectronico' => ['Las credenciales proporcionadas son incorrectas.'],
            ]);
        }

        // Delete all previous tokens
        $user->tokens()->delete();

        // Create new token
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'data' => [
                'id' => $user->id,
                'nombre' => $user->nombre,
                'correoElectronico' => $user->correoElectronico,
                'telefono' => $user->telefono,
                'permiso' => $user->permiso,
            ],
            'access_token' => $token,
            'token_type' => 'Bearer',
        ]);
    }

    /**
     * Logout user (Revoke token)
     */
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Sesión cerrada exitosamente'
        ]);
    }

    /**
     * Get authenticated user
     */
    public function me(Request $request)
    {
        return response()->json([
            'id' => $request->user()->id,
            'nombre' => $request->user()->nombre,
            'correoElectronico' => $request->user()->correoElectronico,
            'telefono' => $request->user()->telefono,
            'permiso' => $request->user()->permiso,
        ]);
    }

    /**
     * Register new user
     */
    public function register(Request $request)
    {
        $request->validate([
            'nombre' => 'required|string|max:255',
            'correoElectronico' => 'required|email|unique:users,correoElectronico',
            'telefono' => 'required|string|max:20',
            'password' => 'required|string|min:6',
            'permiso' => 'in:admin,vendedor,usuario',
        ]);

        $user = User::create([
            'nombre' => $request->nombre,
            'correoElectronico' => $request->correoElectronico,
            'telefono' => $request->telefono,
            'password' => Hash::make($request->password),
            'permiso' => $request->permiso ?? 'usuario',
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'access_token' => $token,
            'token_type' => 'Bearer',
            'user' => [
                'id' => $user->id,
                'nombre' => $user->nombre,
                'correoElectronico' => $user->correoElectronico,
                'telefono' => $user->telefono,
                'permiso' => $user->permiso,
            ]
        ], 201);
    }
}
