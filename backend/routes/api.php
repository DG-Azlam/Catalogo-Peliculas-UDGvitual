<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Models\Movie;
use App\Http\Controllers\MovieController;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::get('/movies', [MovieController::class, 'index']); // Todos los registros
Route::get('/movies/{id}', [MovieController::class, 'show']); // Registro específico
Route::post('/movies', [MovieController::class, 'store']); //POST: Crear registro

Route::put('/movies/{id}', [MovieController::class, 'update']);//PUT: Modificar registo
Route::delete('/movies/{id}', [MovieController::class, 'destroy']);//Delete: Eliminar un registro