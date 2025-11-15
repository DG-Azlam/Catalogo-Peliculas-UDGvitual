# Stage 1: Build Angular
FROM node:22.19-alpine as angular-build

WORKDIR /app/frontend
COPY frontend/ .
RUN npm install --legacy-peer-deps
RUN npx ng build --configuration=production --base-href="/"

# Stage 2: Build Laravel
FROM php:8.2-fpm-alpine as laravel-build

WORKDIR /var/www

# Instalar dependencias
RUN apk add --no-cache \
    nginx \
    git \
    unzip \
    libpng-dev \
    libzip-dev \
    oniguruma-dev \
    postgresql-dev \
    && docker-php-ext-install pdo pdo_pgsql mbstring zip gd

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copiar composer.json
COPY backend/composer.json ./

# Instalar dependencias
RUN composer install --no-dev --optimize-autoloader --no-scripts

# Copiar el resto del código
COPY backend/ .

# SOLUCIÓN: Generar key aquí en Stage 2 donde PHP está disponible
RUN echo "APP_NAME=Laravel" > .env && \
    echo "APP_ENV=production" >> .env && \
    echo "APP_DEBUG=true" >> .env && \
    echo "APP_URL=https://catalogo-peliculas-udgvitual.onrender.com" >> .env && \
    echo "LOG_CHANNEL=stderr" >> .env && \
    echo "DB_CONNECTION=pgsql" >> .env && \
    echo "DB_HOST=dpg-d4bgsnvpm1nc73bq8ph0-a" >> .env && \
    echo "DB_PORT=5432" >> .env && \
    echo "DB_DATABASE=catalogo_5uy5" >> .env && \
    echo "DB_USERNAME=catalogo_5uy5_user" >> .env && \
    echo "DB_PASSWORD=U51sgIhJYXoyeTdPu214V9sdgd7XRkcS" >> .env

# Generar key de Laravel
RUN php artisan key:generate --force

# Configurar permisos
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache && \
    chmod -R 775 storage bootstrap/cache

# Stage 3: Production
FROM nginx:alpine

# Instalar PHP-FPM para el runtime
RUN apk add --no-cache php82-fpm php82-pdo php82-pdo_pgsql php82-mbstring php82-zip php82-gd

WORKDIR /var/www

# Copiar Laravel (incluye .env y key generada)
COPY --from=laravel-build /var/www/ .

# Copiar Angular
COPY --from=angular-build /app/frontend/dist/catalogo_frontend/browser/ /var/www/public/

# Configurar PHP-FPM
RUN echo 'listen = 9000' >> /etc/php82/php-fpm.d/www.conf && \
    echo 'clear_env = no' >> /etc/php82/php-fpm.d/www.conf

# Configurar Nginx
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

# Script de inicio
RUN echo '#!/bin/sh' > /start.sh && \
    echo 'php-fpm82 -D' >> /start.sh && \
    echo 'nginx -g "daemon off;"' >> /start.sh && \
    chmod +x /start.sh

EXPOSE 10000

CMD ["/start.sh"]
