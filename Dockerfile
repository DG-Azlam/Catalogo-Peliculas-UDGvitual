# ========== DOCKERFILE ==========
FROM php:8.2-apache

# Instalar Node.js 22
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
RUN apt-get install -y nodejs

# Dependencias PHP
RUN apt-get update && apt-get install -y \
    git curl libpng-dev libonig-dev libxml2-dev \
    zip unzip libpq-dev \
    && docker-php-ext-install pdo pdo_mysql pdo_pgsql mbstring exif pcntl bcmath gd

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Apache
RUN a2enmod rewrite
COPY backend/ /var/www/html/
WORKDIR /var/www/html

# Laravel
RUN composer install --no-dev --optimize-autoloader
RUN php artisan config:cache && php artisan route:cache && php artisan view:cache

# Angular - SIN PRERENDERING
COPY frontend/ /tmp/frontend/
WORKDIR /tmp/frontend
RUN npm install

# Eliminar prerendering
RUN node -e "\
const fs = require('fs');\n\
let angularJson = JSON.parse(fs.readFileSync('angular.json', 'utf8'));\n\
const projectName = Object.keys(angularJson.projects)[0];\n\
delete angularJson.projects[projectName]?.architect?.server;\n\
delete angularJson.projects[projectName]?.architect?.prerender;\n\
fs.writeFileSync('angular.json', JSON.stringify(angularJson, null, 2));\n\
"

# Construir
RUN npx ng build --configuration=production

# Mover build
WORKDIR /var/www/html
RUN cp -r /tmp/frontend/dist/frontend/* public/

# Permisos
RUN chown -R www-data:www-data /var/www/html && chmod -R 755 storage bootstrap/cache

EXPOSE 80
CMD sh -c "php artisan migrate --force && apache2-foreground"
