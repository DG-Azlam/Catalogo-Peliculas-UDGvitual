# Stage 1: Build Angular
FROM node:22.19-alpine as angular-build

WORKDIR /app/frontend
COPY frontend/ .
RUN npm ci --legacy-peer-deps

# Build Angular
RUN npx ng build --configuration=production --base-href="/"

# Verificar y corregir estructura
RUN echo "=== VERIFICANDO ESTRUCTURA ANGULAR ===" && \
    find dist/ -name "index.html" && \
    # Crear estructura esperada si no existe
    if [ -d "dist/catalogo_frontend/browser" ]; then \
        echo "✅ Estructura correcta encontrada"; \
    else \
        echo "🔄 Ajustando estructura..."; \
        mkdir -p dist/catalogo_frontend/browser && \
        # Buscar y copiar archivos built
        find dist/ -name "*.js" -exec cp {} dist/catalogo_frontend/browser/ \; && \
        find dist/ -name "*.css" -exec cp {} dist/catalogo_frontend/browser/ \; && \
        find dist/ -name "index.html" -exec cp {} dist/catalogo_frontend/browser/ \; && \
        find dist/ -name "assets" -type d -exec cp -r {} dist/catalogo_frontend/browser/ \; 2>/dev/null || true; \
    fi

# Stage 2: Build Laravel
FROM php:8.2-fpm-alpine as laravel-build

WORKDIR /var/www

# Instalar dependencias del sistema
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

# Copiar código de Laravel
COPY backend/ .

# Instalar dependencias de Laravel (sin dev)
RUN composer install --no-dev --optimize-autoloader

# Configurar permisos
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

# Stage 3: Production
FROM nginx:alpine

# Instalar PHP-FPM
RUN apk add --no-cache php82-fpm php82-pdo php82-pdo_pgsql php82-mbstring php82-zip php82-gd

WORKDIR /var/www

# Copiar Laravel
COPY --from=laravel-build /var/www/ .

# Copiar Angular
COPY --from=angular-build /app/frontend/dist/catalogo_frontend/browser/ /var/www/public/

# Configurar PHP-FPM
RUN echo 'listen = 9000' >> /etc/php82/php-fpm.d/www.conf && \
    echo 'clear_env = no' >> /etc/php82/php-fpm.d/www.conf

# Configurar Nginx (desde la carpeta docker)
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

# Script de inicio
RUN echo '#!/bin/sh' > /start.sh && \
    echo 'php-fpm82 -D' >> /start.sh && \
    echo 'nginx -g "daemon off;"' >> /start.sh && \
    chmod +x /start.sh

EXPOSE 10000

CMD ["/start.sh"]
