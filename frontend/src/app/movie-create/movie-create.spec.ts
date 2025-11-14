import { ComponentFixture, TestBed } from '@angular/core/testing';

import { MovieCreate } from './movie-create';

describe('MovieCreate', () => {
  let component: MovieCreate;
  let fixture: ComponentFixture<MovieCreate>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [MovieCreate]
    })
    .compileComponents();

    fixture = TestBed.createComponent(MovieCreate);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
