# ========== DOCKERFILE ==========
FROM php:8.2-apache

# Instalar Node.js 22 para Angular
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
RUN apt-get install -y nodejs

# Dependencias del sistema
RUN apt-get update && apt-get install -y \
    git curl libpng-dev libonig-dev libxml2-dev \
    zip unzip libpq-dev \
    && docker-php-ext-install pdo pdo_mysql pdo_pgsql mbstring exif pcntl bcmath gd \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configurar Apache
RUN a2enmod rewrite
RUN echo '<VirtualHost *:80>\
    DocumentRoot /var/www/html/public\
    <Directory /var/www/html/public>\
        AllowOverride All\
        Require all granted\
    </Directory>\
</VirtualHost>' > /etc/apache2/sites-available/000-default.conf

# Configurar Laravel
WORKDIR /var/www/html
COPY backend/ .
RUN composer install --no-dev --optimize-autoloader
RUN php artisan config:cache && php artisan route:cache && php artisan view:cache

# SOLUCIÓN SIMPLE para Angular - Deshabilitar prerendering
WORKDIR /tmp/angular-fix
COPY frontend/ .

# Crear script simple de fix
RUN echo 'const fs = require("fs"); \
try { \
  let angularJson = JSON.parse(fs.readFileSync("angular.json", "utf8")); \
  let projectName = Object.keys(angularJson.projects)[0]; \
  if (angularJson.projects[projectName].architect) { \
    delete angularJson.projects[projectName].architect.server; \
    delete angularJson.projects[projectName].architect.prerender; \
    if (angularJson.projects[projectName].architect.build?.configurations?.production) { \
      angularJson.projects[projectName].architect.build.configurations.production.prerender = false; \
      delete angularJson.projects[projectName].architect.build.configurations.production.ssr; \
    } \
  } \
  fs.writeFileSync("angular.json", JSON.stringify(angularJson, null, 2)); \
  console.log("Prerendering disabled successfully"); \
} catch(e) { \
  console.log("Error modifying angular.json:", e.message); \
}' > fix.js

# Aplicar fix y construir
RUN npm install
RUN node fix.js
RUN npx ng build --configuration=production --prerender=false

# Preparar aplicación final
WORKDIR /var/www/html
RUN cp -r /tmp/angular-fix/dist/frontend/* public/

# Permisos
RUN chown -R www-data:www-data /var/www/html && chmod -R 755 storage bootstrap/cache

EXPOSE 80
CMD ["apache2-foreground"]
