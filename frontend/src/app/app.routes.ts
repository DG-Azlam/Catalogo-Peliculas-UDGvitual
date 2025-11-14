import { Routes } from '@angular/router';

export const routes: Routes = [
  { 
    path: '', 
    loadComponent: () => import('./index/index').then(m => m.IndexComponent)
  },
  { 
    path: 'movies', 
    children: [
      {
        path: '',
        loadComponent: () => import('./movies/movies').then(m => m.MoviesComponent)
      },
      {
        path: 'create',
        loadComponent: () => import('./movie-create/movie-create').then(m => m.MovieCreateComponent)
      },
      {
        path: 'edit/:id',
        loadComponent: () => import('./movie-edit/movie-edit').then(m => m.MovieEditComponent)
      },
      {
        path: ':id',  
        loadComponent: () => import('./movie/movie').then(m => m.MovieComponent)
      }
    ]
  },
  { path: '**', redirectTo: '' }
];