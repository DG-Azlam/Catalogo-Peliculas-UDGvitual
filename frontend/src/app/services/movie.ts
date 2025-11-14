import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, catchError } from 'rxjs';
import { environment } from '../../environments/environment'; // ← Agrega esta línea

export interface Movie {
  id: number;
  title: string;
  synopsis: string;
  year: number;
  cover: string;
  created_at?: string;
  updated_at?: string;
}

interface ApiResponse<T> {
  message: string;
  data: T;
  count?: number;
}

@Injectable({
  providedIn: 'root'
})
export class MovieService {
  private http = inject(HttpClient);
  
  // Usa la URL desde environment
  private apiUrl = `${environment.apiUrl}/movies`;

  getMovies(): Observable<ApiResponse<Movie[]>> {
    return this.http.get<ApiResponse<Movie[]>>(this.apiUrl).pipe(
      catchError(this.handleError)
    );
  }

  getMovie(id: number): Observable<ApiResponse<Movie>> {
    return this.http.get<ApiResponse<Movie>>(`${this.apiUrl}/${id}`).pipe(
      catchError(this.handleError)
    );
  }

  createMovie(movieData: Omit<Movie, 'id'>): Observable<ApiResponse<Movie>> {
    return this.http.post<ApiResponse<Movie>>(this.apiUrl, movieData).pipe(
      catchError(this.handleError)
    );
  }

  updateMovie(id: number, movieData: Omit<Movie, 'id'>): Observable<ApiResponse<Movie>> {
    return this.http.put<ApiResponse<Movie>>(`${this.apiUrl}/${id}`, movieData).pipe(
      catchError(this.handleError)
    );
  }

  deleteMovie(id: number): Observable<{ message: string }> {
    return this.http.delete<{ message: string }>(`${this.apiUrl}/${id}`).pipe(
      catchError(this.handleError)
    );
  }

  private handleError(error: any): Observable<never> {
    console.error('Service error:', error);
    throw new Error('Error en la comunicación con el servidor');
  }
}