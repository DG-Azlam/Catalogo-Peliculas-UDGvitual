import { bootstrapApplication } from '@angular/platform-browser';
import { App } from './app/app';
import { config } from './app/app.config.server';

// Elimina BootstrapContext para desactivar prerendering
const bootstrap = () => bootstrapApplication(App, config);

export default bootstrap;
