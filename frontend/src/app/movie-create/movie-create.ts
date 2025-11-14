import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { MovieService, Movie } from '../services/movie';

@Component({
  selector: 'app-movie-create',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './movie-create.html',
  })
export class MovieCreateComponent {
  private movieService = inject(MovieService);
  private router = inject(Router);

  movie = signal<Omit<Movie, 'id'>>({
    title: '',
    synopsis: '',
    year: new Date().getFullYear(),
    cover: ''
  });

  loading = signal(false);
  error = signal<string | null>(null);

  //Crear Película
  onSubmit(): void {
    if (this.loading()) return;

    this.loading.set(true);
    this.error.set(null);

    this.movieService.createMovie(this.movie()).subscribe({
      next: (response) => {
        this.loading.set(false);
        alert('🎉 ' + response.message);
        this.router.navigate(['/movies']);
      },
      error: (error) => {
        this.loading.set(false);
        this.error.set(error.message);
        console.error('Error creando película:', error);
      }
    });
  }

  //Regresar al listado de peliculas
  goBack(): void {
    this.router.navigate(['/movies']);
  }

  // Validar si el formulario puede enviarse
  canSubmit(): boolean {
    const currentMovie = this.movie();
    return !this.loading() && 
      currentMovie.title.trim().length > 0 &&
      currentMovie.synopsis.trim().length > 0 &&
      currentMovie.cover.trim().length > 0 &&
      currentMovie.year >= 1900 &&
      currentMovie.year <= 2030;
  }
}