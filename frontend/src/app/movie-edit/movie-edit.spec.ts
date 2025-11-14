import { ComponentFixture, TestBed } from '@angular/core/testing';

import { MovieEdit } from './movie-edit';

describe('MovieEdit', () => {
  let component: MovieEdit;
  let fixture: ComponentFixture<MovieEdit>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [MovieEdit]
    })
    .compileComponents();

    fixture = TestBed.createComponent(MovieEdit);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
