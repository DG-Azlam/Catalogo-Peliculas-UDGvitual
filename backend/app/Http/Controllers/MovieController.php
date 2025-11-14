<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Movie;

class MovieController extends Controller
{
    /** Obtener todas las películas (todos los registros) **/
    public function index()
    {
        // Obtener todos los registros de la tabla movies
        $movies = Movie::all();
        
        return response()->json([
            'message' => 'Lista de todas las peliculas:',
            'data' => $movies,
            'count' => $movies->count()
        ], 200); //Todo bien
    }

    /** Obtener una película específica por ID **/
    public function show($id)
    {
        // Buscar la película por ID
        $movie = Movie::find($id);
        
        // Verificar si la película existe
        if (!$movie) {
            return response()->json([
                'message' => 'Pelicula no encontrada'
            ], 404); //Código de Error 
        }
        
        return response()->json([
            'message' => 'Pelicula encontrada',
            'data' => $movie
        ], 200); //Todo bien   
    }

    /** Crear una nueva película (POST) **/
    public function store(Request $request)
    {
        try {
            // Validar los datos recibidos
            $validatedData = $request->validate([
                'title' => 'required|string',
                'synopsis' => 'required|string',
                'year' => 'required|integer',
                'cover' => 'required|string',
            ]);

            // Crear la nueva película
            $movie = Movie::create($validatedData);

            return response()->json([
                'message' => 'Película registrada exitosamente',
                'data' => $movie
            ], 201); // Código 201 para creado

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'message' => 'Error de validación',
                'errors' => $e->errors()
            ], 422);

        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Error al crear la película',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /** Modificar un registro de pelicula existente (PUT) **/
    public function update(Request $request, $id)
    {
        try {
            // Buscar la película
            $movie = Movie::find($id);
            
            if (!$movie) {
                return response()->json([
                    'message' => 'Película no encontrada'
                ], 404); //No encontrado
            }

            // Validar los datos
            $validatedData = $request->validate([
                'title' => 'required|string',
                'synopsis' => 'required|string',
                'year' => 'required|integer',
                'cover' => 'required|string',
            ]);

            // Actualizar la película
            $movie->update($validatedData);

            return response()->json([
                'message' => 'Película actualizada correctamente',
                'data' => $movie
            ], 200); //Todo bien

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'message' => 'Error de validación',
                'errors' => $e->errors()
            ], 422);
            
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Error al actualizar la película',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Eliminar una película (DELETE)
     */
    public function destroy($id)
    {
        try {
            // Buscar la película
            $movie = Movie::find($id);
            
            if (!$movie) {
                return response()->json([
                    'message' => 'Película no encontrada'
                ], 404);// No encontrado
            }

            // Eliminar la película
            $movie->delete();

            return response()->json([
                'message' => 'Película eliminada correctamente'
            ], 200);//Todo bien

        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Error al eliminar la película',
                'error' => $e->getMessage()
            ], 500);
        }
    }

}
