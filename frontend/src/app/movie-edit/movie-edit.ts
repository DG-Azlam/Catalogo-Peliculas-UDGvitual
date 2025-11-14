import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { MovieService, Movie } from '../services/movie';

@Component({
  selector: 'app-movie-edit',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './movie-edit.html',
  styleUrl: './movie-edit.css'
})
export class MovieEditComponent implements OnInit {
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private movieService = inject(MovieService);

  movie = signal<Movie | null>(null);
  loading = signal(false);
  error = signal<string | null>(null);
  movieId!: number;

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.movieId = +id;
      this.loadMovie();
    } else {
      this.error.set('ID de película no válido');
    }
  }

  loadMovie(): void {
    this.loading.set(true);
    this.error.set(null);

    this.movieService.getMovie(this.movieId).subscribe({
      next: (response) => {
        this.movie.set(response.data);
        this.loading.set(false);
      },
      error: (error) => {
        this.error.set('Error cargando película: ' + error.message);
        this.loading.set(false);
      }
    });
  }

  onSubmit(): void {
    if (this.loading() || !this.movie()) return;

    this.loading.set(true);
    this.error.set(null);

    const movieData = {
      title: this.movie()!.title,
      synopsis: this.movie()!.synopsis,
      year: this.movie()!.year,
      cover: this.movie()!.cover
    };

    this.movieService.updateMovie(this.movieId, movieData).subscribe({
      next: (response) => {
        this.loading.set(false);
        alert('✅ ' + response.message);
        this.router.navigate(['/movies', this.movieId]);
      },
      error: (error) => {
        this.loading.set(false);
        this.error.set(error.message);
      }
    });
  }

  //Regresar al listado de peliculas
  goBack(): void {
    this.router.navigate(['/movies', this.movieId]);
  }

  // Validar si el formulario puede enviarse
  canSubmit(): boolean {
    const currentMovie = this.movie();
    return !this.loading() && 
      currentMovie !== null &&
      currentMovie.title.trim().length > 0 &&
      currentMovie.synopsis.trim().length > 0 &&
      currentMovie.cover.trim().length > 0 &&
      currentMovie.year >= 1900 &&
      currentMovie.year <= 2030;
  }
}