import { Component, inject } from '@angular/core';
import { Router, RouterModule } from '@angular/router';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterModule],
  template: //'./app.html',
    `<router-outlet></router-outlet>`,
  styleUrls: ['./app.css']
})
export class App {
  private router = inject(Router);

  goHome(): void {
    this.router.navigate(['/']);
  }
}