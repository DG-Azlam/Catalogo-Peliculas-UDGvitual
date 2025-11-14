# ========== DOCKERFILE COMPLETO CORREGIDO ==========
FROM php:8.2-apache

# Instalar TODAS las dependencias del sistema
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libpq-dev \
    libzip-dev \
    zip \
    unzip \
    && docker-php-ext-install pdo pdo_mysql pdo_pgsql mbstring zip gd

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configurar Apache
RUN a2enmod rewrite
COPY backend/ /var/www/html/
WORKDIR /var/www/html

# Configurar permisos
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 storage bootstrap/cache

# Instalar dependencias de Laravel
RUN composer install --no-dev --optimize-autoloader

# Configuraciones de Laravel
RUN php artisan config:cache
RUN php artisan route:cache

# Angular - Build simple
COPY frontend/ /tmp/frontend/
WORKDIR /tmp/frontend
RUN npm install
RUN npx ng build --configuration=production

# Mover Angular a Laravel
WORKDIR /var/www/html
RUN cp -r /tmp/frontend/dist/frontend/* public/

EXPOSE 80
CMD sh -c "php artisan migrate --force && apache2-foreground"
