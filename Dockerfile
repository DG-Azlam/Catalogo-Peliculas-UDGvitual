# ========== DOCKERFILE  ==========
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

# Angular - Solución directa
COPY frontend/ /tmp/frontend/
WORKDIR /tmp/frontend
RUN npm install

# Forzar build sin prerendering de múltiples formas
RUN npx ng build --configuration=production --prerender=false || \
    npx ng build --configuration=production --no-prerender || \
    npx ng build --prod

# Mover build a Laravel
WORKDIR /var/www/html
RUN cp -r /tmp/frontend/dist/frontend/* public/

# Permisos
RUN chown -R www-data:www-data /var/www/html && chmod -R 755 storage bootstrap/cache

EXPOSE 80
CMD ["apache2-foreground"]
