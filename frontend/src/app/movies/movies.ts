import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { MovieService, Movie } from '../services/movie';

@Component({
  selector: 'app-movies',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './movies.html'
})
export class MoviesComponent implements OnInit {
  private movieService = inject(MovieService);
  private router = inject(Router);

  movies = signal<Movie[]>([]);
  loading = signal(true);
  error = signal<string | null>(null);
  searchTerm = signal('');

  ngOnInit(): void {
    this.loadMovies();
  }

  loadMovies(): void {
    this.loading.set(true);
    this.error.set(null);

    this.movieService.getMovies().subscribe({
      next: (response) => {
        this.movies.set(response.data);
        this.loading.set(false);
      },
      error: (error) => {
        this.error.set(error.message);
        this.loading.set(false);
      }
    });
  }

  // Busqueda
  filteredMovies = () => {
    const term = this.searchTerm().toLowerCase();
    if (!term) return this.movies();
    
    return this.movies().filter(movie => 
      movie.title.toLowerCase().includes(term) ||
      movie.synopsis.toLowerCase().includes(term)
    );
  };

  onSearchInput(event: Event): void {
    const value = (event.target as HTMLInputElement).value;
    this.searchTerm.set(value);
  }

  viewMovieDetails(id: number): void {
    this.router.navigate(['/movies', id]);
  }

  //Editar Película
  editMovie(movie: Movie, event: Event): void {
    event.stopPropagation(); // Evita que se active el click de la card
    this.router.navigate(['/movies/edit', movie.id]);
  }

  //Eliminar Película
  deleteMovie(movie: Movie, event: Event): void {
    event.stopPropagation(); // Evita que se active el click de la card
    
    if (confirm(`¿Eliminar "${movie.title}"?`)) {
      this.movieService.deleteMovie(movie.id!).subscribe({
        next: () => {
          this.loadMovies(); // Recargar
        },
        error: (error) => {
          alert('Error: ' + error.message);
        }
      });
    }
  }

  //Añadir Película
  createMovie(): void {
    this.router.navigate(['/movies/create']);
  }


}