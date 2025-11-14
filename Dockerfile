# ========== DOCKERFILE ==========
FROM php:8.2-apache

# Node.js 22
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
RUN apt-get install -y nodejs

# Instalar TODAS las dependencias necesarias
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
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

# Angular
COPY frontend/ /tmp/frontend/
WORKDIR /tmp/frontend
RUN npm install

# Build Angular
RUN npx ng build --configuration=production

# Mover a Laravel
WORKDIR /var/www/html
RUN cp -r /tmp/frontend/dist/frontend/* public/

# Permisos
RUN chmod -R 755 storage bootstrap/cache

EXPOSE 80
CMD sh -c "php artisan migrate --force && apache2-foreground"
