<?php

namespace Database\Seeders;

use App\Models\Movie;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class MoviesTableSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        //
        Movie::truncate(); /*Limpia la tabla "Movie"*/
        $faker = \Faker\Factory::create(); /*Asigna a la variable "faker" lo necesario para crear informacion falsa*/
        for ($i = 0; $i < 10; $i++){
            Movie::create([
                'title'=> $faker -> sentence,
                'synopsis' => $faker -> paragraph,
                'year' => $faker -> randomDigit,
                'cover' => $faker -> sentence,
            ]);
        }
    }
}
