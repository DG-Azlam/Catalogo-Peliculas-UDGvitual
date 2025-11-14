import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router } from '@angular/router';
import { MovieService, Movie } from '../services/movie';

@Component({
  selector: 'app-movie',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './movie.html',
  styleUrl: './movie.css'
})
export class MovieComponent implements OnInit {
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private movieService = inject(MovieService);

  movie = signal<Movie | null>(null);
  loading = signal<boolean>(true);
  error = signal<string | null>(null);

  ngOnInit(): void {
    this.loadMovie();
  }

  loadMovie(): void {
    const id = this.route.snapshot.paramMap.get('id');
    
    if (!id) {
      this.error.set('ID de película no válido');
      this.loading.set(false);
      return;
    }

    this.loading.set(true);
    this.error.set(null);

    this.movieService.getMovie(+id).subscribe({
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

  goBack(): void {
    this.router.navigate(['/movies']);
  }

  editMovie(): void {
    if (this.movie()?.id) {
      this.router.navigate(['/movies/edit', this.movie()!.id]);
    }
  }
}