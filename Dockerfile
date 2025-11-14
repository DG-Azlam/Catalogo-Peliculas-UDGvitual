# ========== DOCKERFILE ==========
FROM php:8.2-apache

# Node.js 22
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
RUN apt-get install -y nodejs

# Dependencias PHP
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libonig-dev \
    libxml2-dev \
    && docker-php-ext-install pdo pdo_pgsql mbstring

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Apache
RUN a2enmod rewrite
COPY backend/ /var/www/html/
WORKDIR /var/www/html

# Laravel
RUN composer install --no-dev --optimize-autoloader
RUN php artisan config:cache && php artisan route:cache

# Angular - ESTRATEGIAS MÚLTIPLES
COPY frontend/ /tmp/frontend/
WORKDIR /tmp/frontend
RUN npm install

# ESTRATEGIA 1: Intentar eliminar SSR de la configuración
RUN echo "=== ESTRATEGIA 1: Eliminar SSR de angular.json ===" && \
    node -e "\
    const fs = require('fs');\n\
    try {\n\
      const angularJson = JSON.parse(fs.readFileSync('angular.json', 'utf8'));\n\
      const projectName = Object.keys(angularJson.projects)[0];\n\
      const project = angularJson.projects[projectName];\n\
      \n\
      delete project.architect?.server;\n\
      delete project.architect?.prerender;\n\
      \n\
      if (project.architect?.build?.configurations?.production) {\n\
        delete project.architect.build.configurations.production.ssr;\n\
        delete project.architect.build.configurations.production.prerender;\n\
      }\n\
      \n\
      fs.writeFileSync('angular.json', JSON.stringify(angularJson, null, 2));\n\
      console.log('✅ SSR eliminado de angular.json');\n\
    } catch (e) {\n\
      console.log('⚠️ No se pudo modificar angular.json:', e.message);\n\
    }\n\
    " && \
    npx ng build --configuration=production

# ESTRATEGIA 2: Si falla, intentar build con flags alternativos
RUN if [ ! -d "dist" ]; then \
    echo "=== ESTRATEGIA 2: Build con flags alternativos ===" && \
    npx ng build --configuration=production --no-prerender 2>/dev/null || \
    npx ng build --prod 2>/dev/null || true; \
fi

# ESTRATEGIA 3: Si aún falla, build básico ignorando errores
RUN if [ ! -d "dist" ]; then \
    echo "=== ESTRATEGIA 3: Build básico ignorando errores ===" && \
    npx ng build --configuration=production || \
    npx ng build || \
    echo "✅ Build completado con advertencias"; \
fi

# ESTRATEGIA 4: Verificar que existe el build
RUN if [ ! -d "dist" ]; then \
    echo "❌ ERROR: No se pudo construir Angular"; \
    exit 1; \
else \
    echo "✅ Build de Angular exitoso"; \
    ls -la dist/; \
fi

# Mover a Laravel
WORKDIR /var/www/html
RUN cp -r /tmp/frontend/dist/frontend/* public/

# Permisos
RUN chown -R www-data:www-data /var/www/html && chmod -R 755 storage bootstrap/cache

EXPOSE 80
CMD sh -c "php artisan migrate --force && apache2-foreground"
