# ========== DOCKERFILE CORREGIDO ==========
FROM php:8.2-apache

# 1. Instalar Node.js 22 CORRECTAMENTE
RUN apt-get update && apt-get install -y curl
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
RUN apt-get install -y nodejs

# Verificar instalación
RUN node --version && npm --version

# 2. Dependencias PHP
RUN apt-get install -y \
    git \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libpq-dev \
    libzip-dev \
    zip \
    unzip \
    && docker-php-ext-install pdo pdo_pgsql mbstring zip gd

# 3. Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 4. Apache
RUN a2enmod rewrite
COPY backend/ /var/www/html/
WORKDIR /var/www/html

# 5. Permisos
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 storage bootstrap/cache

# 6. Laravel
RUN composer install --no-dev --optimize-autoloader
RUN php artisan config:cache
RUN php artisan route:cache

# 7. Angular - CON NODE.JS FUNCIONANDO
COPY frontend/ /tmp/frontend/
WORKDIR /tmp/frontend
RUN npm install
RUN npx ng build --configuration=production

# 8. Combinar
WORKDIR /var/www/html
RUN cp -r /tmp/frontend/dist/frontend/* public/

EXPOSE 80
CMD sh -c "php artisan migrate --force && apache2-foreground"
