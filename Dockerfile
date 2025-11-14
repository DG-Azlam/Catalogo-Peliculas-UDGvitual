# Stage 1: Build Angular frontend with Node 22.19
FROM node:22.19-alpine as angular-build

WORKDIR /app/frontend

# Copy package files
COPY frontend/package*.json ./

# Clean install
RUN npm ci --legacy-peer-deps

# Copy frontend source code
COPY frontend/ .

# Build SIN prerendering
RUN npx ng build --configuration=production

# Stage 2: Build Laravel backend with frontend
FROM php:8.2-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git curl libpng-dev libonig-dev libxml2-dev \
    zip unzip libpq-dev nginx

# Install PHP extensions
RUN docker-php-ext-install pdo pdo_pgsql mbstring exif pcntl bcmath gd

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www

# Copy Laravel backend
COPY backend/ .

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader

# Copy built Angular frontend 
COPY --from=angular-build /app/frontend/dist/catalogo_frontend/browser/ /var/www/public/

# Set permissions
RUN chown -R www-data:www-data /var/www/storage
RUN chown -R www-data:www-data /var/www/bootstrap/cache
RUN chmod -R 775 /var/www/storage
RUN chmod -R 775 /var/www/bootstrap/cache

# Copy nginx configuration
COPY docker/nginx.conf /etc/nginx/sites-available/default

# Expose port
EXPOSE 10000

# Startup script
CMD sh -c "php artisan config:cache && \
           php artisan route:cache && \
           php artisan migrate --force && \
           nginx -g 'daemon off;' & php-fpm"
